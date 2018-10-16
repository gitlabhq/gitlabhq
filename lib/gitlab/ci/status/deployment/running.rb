module Gitlab
  module Ci
    module Status
      module Deployment
        class Running < Status::Extended
          def environment_text
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
