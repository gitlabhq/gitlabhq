module Gitlab
  module Ci
    module Status
      module Build
        class Cancelable < Status::Extended
          def has_action?
            can?(user, :update_build, subject)
          end

          def action_icon
            'icon_action_cancel'
          end

          def action_path
            cancel_namespace_project_build_path(subject.project.namespace,
                                                subject.project,
                                                subject)
          end

          def action_method
            :post
          end

          def action_title
            'Cancel'
          end

          def self.matches?(build, user)
            build.cancelable?
          end
        end
      end
    end
  end
end
