# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Build
        class WaitingForApproval < Status::Extended
          def illustration
            {
              image: 'illustrations/manual_action.svg',
              size: 'svg-394',
              title: 'Waiting for approval',
              content: "This job deploys to the protected environment \"#{subject.deployment&.environment&.name}\" which requires approvals. Use the Deployments API to approve or reject the deployment."
            }
          end

          def self.matches?(build, user)
            build.waiting_for_deployment_approval?
          end
        end
      end
    end
  end
end
