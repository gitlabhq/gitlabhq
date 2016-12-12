module Gitlab
  module Ci
    module Status
      module Build
        class Stop < SimpleDelegator
          include Status::Extended

          def text
            'stop'
          end

          def label
            'stop'
          end

          def icon
            'icon_status_skipped'
          end

          def has_action?
            can?(user, :update_build, subject)
          end

          def action_icon
            'stop'
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
