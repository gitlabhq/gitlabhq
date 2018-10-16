module Gitlab
  module Ci
    module Status
      module Deployment
        class Canceled < Status::Extended
          def environment_text
            "This job was canceled to deploy to %{environment_path}."
          end

          def self.matches?(deployment, user)
            deployment.canceled?
          end
        end
      end
    end
  end
end
