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
              image: 'illustrations/empty-state/empty-job-manual-md.svg',
              size: '',
              title: _('This job requires a manual action'),
              content: illustration_content
            }
          end

          private

          def illustration_content
            if can?(user, :update_build, subject)
              manual_job_action_message
            else
              generic_permission_failure_message
            end
          end

          def manual_job_action_message
            if subject.retryable?
              _("You can modify this job's CI/CD variables before running it again.")
            else
              _('This job does not start automatically and must be started manually. You can add CI/CD variables below for last-minute configuration changes before starting the job.')
            end
          end

          def generic_permission_failure_message
            if subject.has_outdated_deployment?
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
