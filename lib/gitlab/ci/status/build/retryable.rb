module Gitlab
  module Ci
    module Status
      module Build
        class Retryable < Status::Extended
          def has_action?
            can?(user, :update_build, subject)
          end

          def action_icon
            'retry'
          end

          def action_title
            'Retry'
          end

          def action_button_title
            _('Retry this job')
          end

          def action_path
            retry_project_job_path(subject.project, subject)
          end

          def action_method
            :post
          end

          def self.matches?(build, user)
            build.retryable?
          end
        end
      end
    end
  end
end
