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
              title: _('Waiting for approval'),
              content: _("This job deploys to the protected environment \"%{environment}\" which requires approvals.") % { environment: subject.deployment&.environment&.name }
            }
          end

          def has_action?
            true
          end

          def action_icon
            nil
          end

          def action_title
            nil
          end

          def action_button_title
            _('Go to environments page to approve or reject')
          end

          def action_path
            project_environments_path(subject.project)
          end

          def action_method
            :get
          end

          def self.matches?(build, user)
            build.waiting_for_deployment_approval?
          end
        end
      end
    end
  end
end
