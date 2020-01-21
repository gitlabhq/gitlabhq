# frozen_string_literal: true

module Gitlab
  module Ci
    class Trace
      include ::Gitlab::ExclusiveLeaseHelpers
      include Checksummable

      LOCK_TTL = 10.minutes
      LOCK_RETRIES = 2
      LOCK_SLEEP = 0.001.seconds
      WATCH_FLAG_TTL = 10.seconds

      UPDATE_FREQUENCY_DEFAULT = 30.seconds
      UPDATE_FREQUENCY_WHEN_BEING_WATCHED = 3.seconds

      ArchiveError = Class.new(StandardError)
      AlreadyArchivedError = Class.new(StandardError)

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
        write('w+b') do |stream|
          data = job.hide_secrets(data)
          stream.set(data)
        end
      end

      def append(data, offset)
        write('a+b') do |stream|
          current_length = stream.size
          break current_length unless current_length == offset

          data = job.hide_secrets(data)
          stream.append(data, offset)
          stream.size
        end
      end

      def exist?
        archived_trace_exist? || live_trace_exist?
      end

      def archived_trace_exist?
        trace_artifact&.exists?
      end

      def live_trace_exist?
        job.trace_chunks.any? || current_path.present? || old_trace.present?
      end

      def read
        stream = Gitlab::Ci::Trace::Stream.new do
          if trace_artifact
            trace_artifact.open
          elsif job.trace_chunks.any?
            Gitlab::Ci::Trace::ChunkedIO.new(job)
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

      def write(mode, &blk)
        in_write_lock do
          unsafe_write!(mode, &blk)
        end
      end

      def erase!
        ##
        # Erase the archived trace
        trace_artifact&.destroy!

        ##
        # Erase the live trace
        job.trace_chunks.fast_destroy_all # Destroy chunks of a live trace
        FileUtils.rm_f(current_path) if current_path # Remove a trace file of a live trace
        job.erase_old_trace! if job.has_old_trace? # Remove a trace in database of a live trace
      ensure
        @current_path = nil
      end

      def archive!
        in_write_lock do
          unsafe_archive!
        end
      end

      def update_interval
        being_watched? ? UPDATE_FREQUENCY_WHEN_BEING_WATCHED : UPDATE_FREQUENCY_DEFAULT
      end

      def being_watched!
        Gitlab::Redis::SharedState.with do |redis|
          redis.set(being_watched_cache_key, true, ex: WATCH_FLAG_TTL)
        end
      end

      def being_watched?
        Gitlab::Redis::SharedState.with do |redis|
          redis.exists(being_watched_cache_key)
        end
      end

      private

      def unsafe_write!(mode, &blk)
        stream = Gitlab::Ci::Trace::Stream.new do
          if trace_artifact
            raise AlreadyArchivedError, 'Could not write to the archived trace'
          elsif current_path
            File.open(current_path, mode)
          elsif Feature.enabled?('ci_enable_live_trace', job.project)
            Gitlab::Ci::Trace::ChunkedIO.new(job)
          else
            File.open(ensure_path, mode)
          end
        end

        yield(stream).tap do
          job.touch if job.needs_touch?
        end
      ensure
        stream&.close
      end

      def unsafe_archive!
        raise AlreadyArchivedError, 'Could not archive again' if trace_artifact
        raise ArchiveError, 'Job is not finished yet' unless job.complete?

        if job.trace_chunks.any?
          Gitlab::Ci::Trace::ChunkedIO.new(job) do |stream|
            archive_stream!(stream)
            stream.destroy!
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

      def in_write_lock(&blk)
        lock_key = "trace:write:lock:#{job.id}"
        in_lock(lock_key, ttl: LOCK_TTL, retries: LOCK_RETRIES, sleep_sec: LOCK_SLEEP, &blk)
      end

      def archive_stream!(stream)
        clone_file!(stream, JobArtifactUploader.workhorse_upload_path) do |clone_path|
          create_build_trace!(job, clone_path)
        end
      end

      def clone_file!(src_stream, temp_dir)
        FileUtils.mkdir_p(temp_dir)
        Dir.mktmpdir("tmp-trace-#{job.id}", temp_dir) do |dir_path|
          temp_path = File.join(dir_path, "job.log")
          FileUtils.touch(temp_path)
          size = IO.copy_stream(src_stream, temp_path)
          raise ArchiveError, 'Failed to copy stream' unless size == src_stream.size

          yield(temp_path)
        end
      end

      def create_build_trace!(job, path)
        File.open(path) do |stream|
          # TODO: Set `file_format: :raw` after we've cleaned up legacy traces migration
          # https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/20307
          job.create_job_artifacts_trace!(
            project: job.project,
            file_type: :trace,
            file: stream,
            file_sha256: self.class.hexdigest(path))
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
        [default_path]
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

      def trace_artifact
        job.job_artifacts_trace
      end

      def being_watched_cache_key
        "gitlab:ci:trace:#{job.id}:watched"
      end
    end
  end
end
