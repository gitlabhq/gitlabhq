module Gitlab
  module Ci
    module Status
      module Deployment
        class Running < Status::Extended
          def environment_text
            "This job is deploying to %{environmentLink}."
          end

          def self.matches?(deployment, user)
            deployment.running?
          end
        end
      end
    end
  end
end
