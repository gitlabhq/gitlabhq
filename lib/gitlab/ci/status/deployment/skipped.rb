module Gitlab
  module Ci
    module Status
      module Deployment
        class Skipped < Status::Extended
          def environment_text
            "This job was skipped and did not deploy to %{environmentLink}."
          end

          def self.matches?(deployment, user)
            deployment.skipped?
          end
        end
      end
    end
  end
end
