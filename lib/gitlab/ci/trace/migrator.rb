module Gitlab
  module Ci
    class Trace
      class Migrator
        include Gitlab::Utils::StrongMemoize

        JobNotCompletedError = Class.new(StandardError)
        TraceArtifactDuplicateError = Class.new(StandardError)

        attr_reader :path

        def initialize(relative_path)
          @path = File.join(Settings.gitlab_ci.builds_path, relative_path)
        end

        def perform
          raise ArgumentError, "Trace file not found" unless File.exist?(path)
          raise ArgumentError, "Invalid trace path format" unless trace_path?

          backup!
          migrate!
        end

        private

        def trace_path?
          %r{#{Settings.gitlab_ci.builds_path}/\d{4}_\d{2}/\d{1,}/\d{1,}.log} =~ path
        end

        def status
          strong_memoize(:status) do
            if !job || !job.project
              :not_found
            elsif !job.complete?
              raise JobNotCompletedError
            elsif job.job_artifacts_trace
              raise TraceArtifactDuplicateError
            else
              :migratable
            end
          end
        end

        def job
          @job ||= ::Ci::Build.find_by(id: job_id)
        end

        def job_id
          @job_id ||= File.basename(path, '.log')&.to_i
        end

        def backup_path
          strong_memoize(:backup_path) do
            case status
            when :not_found
              path.gsub(/(\d{4}_\d{2})/, '\1_not_found')
            when :migratable
              path.gsub(/(\d{4}_\d{2})/, '\1_migrated')
            end
          end
        end

        def backup_dir
          @backup_dir ||= File.dirname(backup_path)
        end

        def backup!
          FileUtils.mkdir_p(backup_dir)

          if status == :migratable
            FileUtils.cp(path, backup_path)
          else
            FileUtils.mv(path, backup_path)
          end
        end

        def migrate!
          return unless status == :migratable

          File.open(path) do |stream|
            job.create_job_artifacts_trace!(
              project: job.project,
              file_type: :trace,
              file: stream)
          end
        rescue
          FileUtils.rm(backup_path)
        end
      end
    end
  end
end
