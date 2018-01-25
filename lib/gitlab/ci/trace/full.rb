module Gitlab
  module Ci
    module Trace
      class Full < Gitlab::Ci::Trace
        delegate :old_trace, to: :job

        def exist?
          job.job_artifacts_trace&.exists? || old_trace.present?
        end

        def erase!
          job.job_artifacts_trace.destory if job.job_artifacts_trace
          FileUtils.rm(deprecated_path, force: true) if File.exist?(deprecated_path)

          job.erase_old_trace!
        end

        private

        def ensure_path
          raise 'Full trace does not allow write operation'
        end

        def ensure_directory
          raise 'Full trace does not allow write operation'
        end

        def paths
          raise 'Full trace does not allow write operation'
        end

        def current_path
          raise 'Full trace does not allow write operation'
        end

        def default_directory
          raise 'Full trace does not allow write operation'
        end

        def default_path
          raise 'Full trace does not allow write operation'
        end

        def deprecated_path
          File.join(
            Settings.gitlab_ci.builds_path,
            job.created_at.utc.strftime("%Y_%m"),
            job.project.ci_id.to_s,
            "#{job.id}.log"
          ) if job.project&.ci_id
        end

        def io_read
          if job.job_artifacts_trace
            job.job_artifacts_trace.open
          elsif File.exist?(deprecated_path)
            File.open(deprecated_path, "rb")
          elsif old_trace
            StringIO.new(old_trace)
          end
        end

        def io_write
          raise 'Full trace does not allow write operation'
        end
      end
    end
  end
end
