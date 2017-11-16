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
            'Play'
          end

          def action_path
            play_project_job_path(subject.project, subject)
          end

          def action_method
            :post
          end

          def self.matches?(build, user)
            build.playable? && !build.stops_environment?
          end
        end
      end
    end
  end
end
