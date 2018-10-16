module Gitlab
  module Ci
    module Status
      module Deployment
        class Canceled < Status::Extended
          def environment_text
            "This job was canceled to deploy to %{environmentLink}."
          end

          def self.matches?(deployment, user)
            deployment.canceled?
          end
        end
      end
    end
  end
end
