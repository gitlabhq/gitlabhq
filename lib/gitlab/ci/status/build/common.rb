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

          def action_type
            case
            when @subject.playable? then :playable
            when @subject.active? then :cancel
            when @subject.retryable? then :retry
            end
          end

          def has_action?(current_user)
            action_type && can?(current_user, :update_build, @subject)
          end

          def action_icon
            case action_type
            when :playable then 'remove'
            when :cancel then 'icon_play'
            when :retry then 'repeat'
            end
          end

          def action_path
            case action_type
            when :playable
              play_namespace_project_build_path(subject.project.namespace, subject.project, subject)
            when :cancel
              cancel_namespace_project_build_path(subject.project.namespace, subject.project, subject)
            when :retry
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
