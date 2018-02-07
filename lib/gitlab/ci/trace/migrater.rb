module Gitlab
  module Ci
    class Trace
      class Migrater
        include Gitlab::Utils::StrongMemoize

        attr_reader :path

        def initialize(path)
          raise "File not found: #{path}" unless File.exists?(path)

          @path = path
        end

        def perform
          backup!
          migrate!
        end

        private

        def status
          strong_memoize(:status) do
            if !job
              :not_found
            elsif !job.complete?
              :not_completed
            elsif job.job_artifacts_trace
              :duplicate
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
            when :not_completed
              path.gsub(/(\d{4}_\d{2})/, '\1_not_completed')
            when :duplicate
              path.gsub(/(\d{4}_\d{2})/, '\1_duplicate')
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
        end
      end
    end
  end
end
