# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Build
        class Unschedule < Status::Extended
          def label
            'unschedule action'
          end

          def has_action?
            can?(user, :update_build, subject)
          end

          def action_icon
            'time-out'
          end

          def action_title
            'Unschedule'
          end

          def action_button_title
            _('Unschedule job')
          end

          def action_path
            unschedule_project_job_path(subject.project, subject)
          end

          def action_method
            :post
          end

          def self.matches?(build, user)
            build.scheduled?
          end
        end
      end
    end
  end
end
