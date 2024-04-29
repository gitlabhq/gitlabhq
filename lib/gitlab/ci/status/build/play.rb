# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Build
        class Play < Status::Extended
          def label
            'manual play action'
          end

          def has_action?
            can?(user, :update_build, subject)
          end

          def action_icon
            'play'
          end

          def action_title
            'Run'
          end

          def action_button_title
            _('Run job')
          end

          def action_path
            play_project_job_path(subject.project, subject)
          end

          def action_method
            :post
          end

          def confirmation_message
            subject.manual_confirmation_message
          end

          def self.matches?(build, user)
            build.playable? && !build.stops_environment?
          end
        end
      end
    end
  end
end
