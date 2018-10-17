module Gitlab
  module Ci
    module Status
      module Deployment
        class Failed < Status::Extended
          def environment_text_for_pipeline
            "Failed to deploy to %{environment_path}."
          end

          def environment_text_for_job
            "The deployment of this job to %{environment_path} did not succeed."
          end

          def self.matches?(deployment, user)
            deployment.failed?
          end
        end
      end
    end
  end
end
