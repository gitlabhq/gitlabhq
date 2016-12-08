module Gitlab
  module Ci
    module Status
      module Build
        module Common
          def has_details?
            true
          end

          def details_path
            namespace_project_build_path(@subject.project.namespace,
                                         @subject.project,
                                         @subject.pipeline)
          end

          def has_action?(current_user)
            (subject.cancelable? || subject.retryable?) &&
              can?(current_user, :update_build, @subject)
          end

          def action_icon
            case
            when subject.cancelable? then 'icon_play'
            when subject.retryable? then 'repeat'
            end
          end

          def action_path
            case
            when subject.cancelable?
              cancel_namespace_project_build_path(subject.project.namespace, subject.project, subject)
            when subject.retryable?
              retry_namespace_project_build_path(subject.project.namespace, subject.project, subject)
            end
          end

          def action_method
            :post
          end
        end
      end
    end
  end
end
