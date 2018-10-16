module Gitlab
  module Ci
    module Status
      module Deployment
        class Failed < Status::Extended
          def environment_text
            "The deployment of this job to %{environmentLink} did not succeed."
          end

          def self.matches?(deployment, user)
            deployment.failed?
          end
        end
      end
    end
  end
end
