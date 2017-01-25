module Gitlab
  module Ci
    module Status
      module Build
        class Stop < SimpleDelegator
          include Status::Extended

          def text
            'manual'
          end

          def label
            'manual stop action'
          end

          def icon
            'icon_status_manual'
          end

          def group
            'manual'
          end

          def has_action?
            can?(user, :update_build, subject)
          end

          def action_icon
            'icon_action_stop'
          end

          def action_title
            'Stop'
          end

          def action_path
            play_namespace_project_build_path(subject.project.namespace,
                                              subject.project,
                                              subject)
          end

          def action_method
            :post
          end

          def self.matches?(build, user)
            build.playable? && build.stops_environment?
          end
        end
      end
    end
  end
end
