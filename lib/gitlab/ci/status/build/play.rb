module Gitlab
  module Ci
    module Status
      module Build
        class Play < SimpleDelegator
          include Status::Extended

          def text
            'play'
          end

          def label
            'play'
          end

          def has_action?
            can?(user, :update_build, subject)
          end

          def action_icon
            'play'
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
            build.playable? && !build.stops_environment?
          end
        end
      end
    end
  end
end
