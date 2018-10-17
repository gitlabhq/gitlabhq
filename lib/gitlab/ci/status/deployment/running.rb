module Gitlab
  module Ci
    module Status
      module Deployment
        class Running < Status::Extended
          def environment_text_for_pipeline
            "Deploying to %{environment_path}."
          end

          def environment_text_for_job
            "This job is deploying to %{environment_path}."
          end

          def self.matches?(deployment, user)
            deployment.running?
          end
        end
      end
    end
  end
end
