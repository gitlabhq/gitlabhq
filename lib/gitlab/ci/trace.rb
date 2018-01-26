##
# Current status of paths
# Era 1: Live/Full traces in database (ci_builds.trace)
# Era 2: Live/Full traces in `setting_root/YYYY_MM/project_ci_id/job_id.log`
# Era 3: Live/Full traces in `setting_root/YYYY_MM/project_id/job_id.log`
# Era 4: Live traces in `setting_root/live_trace/job_id.log`. Full traces in JobArtifactUploader#legacy_default_path.
#
# The legacy paths are to be migrated to the latest era.
module Gitlab
  module Ci
    class Trace
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
        trace_artifact&.exists? || current_path.present? || old_trace.present?
      end

      def read
        stream = Gitlab::Ci::Trace::Stream.new do
          if trace_artifact&.exists?
            trace_artifact.open
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
          File.open(ensure_path, "a+b")
        end

        yield(stream).tap do
          job.touch if job.needs_touch?
        end
      ensure
        stream&.close
      end

      def erase!
        trace_artifact&.destory

        paths.each do |trace_path|
          FileUtils.rm(trace_path, force: true)
        end

        job.erase_old_trace!
      end

      private

      def ensure_path
        return current_path if current_path

        ensure_directory
        live_trace_default_path
      end

      def ensure_directory
        unless Dir.exist?(live_trace_default_directory)
          FileUtils.mkdir_p(live_trace_default_directory)
        end
      end

      def current_path
        @current_path ||= paths.find do |trace_path|
          File.exist?(trace_path)
        end
      end

      ##
      # This method doesn't include the latest path, which is JobArtifactUploader#default_path,
      # Because, in EE, traces can be moved to ObjectStorage, so checking paths in Filestorage doesn't make sense.
      # All legacy paths (`legacy_default_path` and `deprecated_path`) are to be migrated to JobArtifactUploader#default_path
      def paths
        [
          live_trace_default_path,
          legacy_default_path,
          deprecated_path
        ].compact
      end

      def live_trace_default_directory
        File.join(
          Settings.gitlab_ci.builds_path,
          'live_trace'
        )
      end

      def live_trace_default_path
        File.join(live_trace_default_directory, "#{job.id}.log")
      end

      def legacy_default_path
        File.join(
          Settings.gitlab_ci.builds_path,
          job.created_at.utc.strftime("%Y_%m"),
          job.project_id.to_s,
          "#{job.id}.log")
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
