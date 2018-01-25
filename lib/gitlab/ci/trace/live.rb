module Gitlab
  module Ci
    module Trace
      class Live < Gitlab::Ci::Trace
        def exist?
          current_path.present?
        end

        def erase!
          paths.each do |trace_path|
            FileUtils.rm(trace_path, force: true)
          end
        end

        private

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

        def paths
          [default_path]
        end

        def current_path
          @current_path ||= paths.find do |trace_path|
            File.exist?(trace_path)
          end
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

        def io_read
          File.open(current_path, "rb") if current_path
        end

        def io_write
          File.open(ensure_path, "a+b")
        end
      end
    end
  end
end
