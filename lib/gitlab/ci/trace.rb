module Gitlab
  module Ci
    class Trace
      ArchiveError = Class.new(StandardError)

      attr_reader :job

      delegate :old_trace, to: :job

      def initialize(job)
        @job = job
      end

      def html(last_lines: nil)
        read do |stream|
          stream.html(last_lines: last_lines)
        end
      end

      def raw(last_lines: nil)
        read do |stream|
          stream.raw(last_lines: last_lines)
        end
      end

      def extract_coverage(regex)
        read do |stream|
          stream.extract_coverage(regex)
        end
      end

      def extract_sections
        read do |stream|
          stream.extract_sections
        end
      end

      def set(data)
        write do |stream|
          data = job.hide_secrets(data)
          stream.set(data)
        end
      end

      def append(data, offset)
        write do |stream|
          current_length = stream.size
          return -current_length unless current_length == offset

          data = job.hide_secrets(data)
          stream.append(data, offset)
          stream.size
        end
      end

      def exist?
        trace_artifact&.exists? || ChunkedFile::LiveTrace.exist?(job.id) || current_path.present? || old_trace.present?
      end

      def read
        stream = Gitlab::Ci::Trace::Stream.new do
          if trace_artifact
            trace_artifact.open
          elsif ChunkedFile::LiveTrace.exist?(job.id)
            ChunkedFile::LiveTrace.new(job.id, nil, "rb")
          elsif current_path
            File.open(current_path, "rb")
          elsif old_trace
            StringIO.new(old_trace)
          end
        end

        yield stream
      ensure
        stream&.close
      end

      def write
        stream = Gitlab::Ci::Trace::Stream.new do
          if Feature.enabled?('ci_enable_live_trace')
            if current_path
              current_path
            else
              ChunkedFile::LiveTrace.new(job.id, nil, "a+b")
            end
          else
            File.open(ensure_path, "a+b")
          end
        end

        yield(stream).tap do
          job.touch if job.needs_touch?
        end
      ensure
        stream&.close
      end

      def erase!
        trace_artifact&.destroy

        ChunkedFile::LiveTrace.new(job.id, nil, 'a+b') do |stream|
          stream.delete
        end

        paths.each do |trace_path|
          FileUtils.rm(trace_path, force: true)
        end

        job.erase_old_trace!
      end

      def archive!
        raise ArchiveError, 'Already archived' if trace_artifact
        raise ArchiveError, 'Job is not finished yet' unless job.complete?

        if ChunkedFile::LiveTrace.exist?(job.id)
          ChunkedFile::LiveTrace.new(job.id, nil, 'a+b') do |live_trace_stream|
            StringIO.new(live_trace_stream.read, 'rb').tap do |stream|
              archive_stream!(stream)
            end

            live_trace_stream.delete
          end
        elsif current_path
          File.open(current_path) do |stream|
            archive_stream!(stream)
            FileUtils.rm(current_path)
          end
        elsif old_trace
          StringIO.new(old_trace, 'rb').tap do |stream|
            archive_stream!(stream)
            job.erase_old_trace!
          end
        end
      end

      private

      def archive_stream!(stream)
        clone_file!(stream, JobArtifactUploader.workhorse_upload_path) do |clone_path|
          create_job_trace!(job, clone_path)
        end
      end

      def clone_file!(src_stream, temp_dir)
        FileUtils.mkdir_p(temp_dir)
        Dir.mktmpdir('tmp-trace', temp_dir) do |dir_path|
          temp_path = File.join(dir_path, "job.log")
          FileUtils.touch(temp_path)
          size = IO.copy_stream(src_stream, temp_path)
          raise ArchiveError, 'Failed to copy stream' unless size == src_stream.size

          yield(temp_path)
        end
      end

      def create_job_trace!(job, path)
        File.open(path) do |stream|
          job.create_job_artifacts_trace!(
            project: job.project,
            file_type: :trace,
            file: stream,
            file_sha256: Digest::SHA256.file(path).hexdigest)
        end
      end

      def ensure_path
        return current_path if current_path

        ensure_directory
        default_path
      end

      def ensure_directory
        unless Dir.exist?(default_directory)
          FileUtils.mkdir_p(default_directory)
        end
      end

      def current_path
        @current_path ||= paths.find do |trace_path|
          File.exist?(trace_path)
        end
      end

      def paths
        [
          default_path,
          deprecated_path
        ].compact
      end

      def default_directory
        File.join(
          Settings.gitlab_ci.builds_path,
          job.created_at.utc.strftime("%Y_%m"),
          job.project_id.to_s
        )
      end

      def default_path
        File.join(default_directory, "#{job.id}.log")
      end

      def deprecated_path
        File.join(
          Settings.gitlab_ci.builds_path,
          job.created_at.utc.strftime("%Y_%m"),
          job.project.ci_id.to_s,
          "#{job.id}.log"
        ) if job.project&.ci_id
      end

      def trace_artifact
        job.job_artifacts_trace
      end
    end
  end
end
