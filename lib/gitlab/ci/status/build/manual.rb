# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Build
        class Manual < Status::Extended
          def self.matches?(build, user)
            build.playable?
          end

          def illustration
            {
              image: 'illustrations/manual_action.svg',
              size: 'svg-394',
              title: _('This job requires a manual action'),
              content: illustration_content
            }
          end

          private

          def illustration_content
            if can?(user, :update_build, subject)
              _('This job requires manual intervention to start. Before starting this job, you can add variables below for last-minute configuration changes.')
            else
              generic_permission_failure_message
            end
          end

          def generic_permission_failure_message
            if subject.outdated_deployment?
              _("This deployment job does not run automatically and must be started manually, but it's older than the latest deployment, and therefore can't run.")
            else
              _("This job does not run automatically and must be started manually, but you do not have access to it.")
            end
          end
        end
      end
    end
  end
end

Gitlab::Ci::Status::Build::Manual.prepend_mod_with('Gitlab::Ci::Status::Build::Manual')
