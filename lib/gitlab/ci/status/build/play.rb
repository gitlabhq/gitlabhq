module Gitlab
  module Ci
    module Status
      module Status
        class Play < SimpleDelegator
          extend Status::Extended

          def text
            'play'
          end

          def label
            'play'
          end

          def icon
            'icon_status_skipped'
          end

          def to_s
            'play'
          end

          def has_action?(current_user)
            can?(current_user, :update_build, subject)
          end

          def action_icon
            :play
          end

          def action_path
            play_namespace_project_build_path(subject.project.namespace, subject.project, subject)
          end

          def action_method
            :post
          end

          def self.matches?(build)
            build.playable? && !build.stops_environment?
          end
        end
      end
    end
  end
end
