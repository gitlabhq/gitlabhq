module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Validate
          class Abilities < Chain::Base
            include Gitlab::Allowable
            include Chain::Helpers

            def perform!
              unless project.builds_enabled?
                return error('Pipelines are disabled!')
              end

              unless allowed_to_trigger_pipeline?
                if can?(current_user, :create_pipeline, project)
                  return error("Insufficient permissions for protected ref '#{command.ref}'")
                else
                  return error('Insufficient permissions to create a new pipeline')
                end
              end
            end

            def break?
              @pipeline.errors.any?
            end

            def allowed_to_trigger_pipeline?
              if current_user
                allowed_to_create?
              else # legacy triggers don't have a corresponding user
                !@command.protected_ref?
              end
            end

            def allowed_to_create?
              return unless can?(current_user, :create_pipeline, project)

              access = Gitlab::UserAccess.new(current_user, project: project)

              if @command.branch_exists?
                access.can_update_branch?(@command.ref)
              elsif @command.tag_exists?
                access.can_create_tag?(@command.ref)
              else
                true # Allow it for now and we'll reject when we check ref existence
              end
            end
          end
        end
      end
    end
  end
end
