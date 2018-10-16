module Gitlab
  module Ci
    module Status
      module Deployment
        class Scheduled < Status::Extended
          def environment_text
            "This job is scheduled to deploy to %{environmentLink}."
          end

          def self.matches?(deployment, user)
            deployment.scheduled?
          end
        end
      end
    end
  end
end
