# frozen_string_literal: true

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
            'Run again'
          end

          def action_button_title
            _('Run this job again')
          end

          def action_path
            retry_project_job_path(subject.project, subject)
          end

          def action_method
            :post
          end

          def confirmation_message
            subject.manual_confirmation_message
          end

          def self.matches?(build, user)
            build.retryable?
          end
        end
      end
    end
  end
end
