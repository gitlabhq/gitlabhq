module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Validate < Chain::Base
          include Gitlab::Allowable

          def perform!
            validate_project! || validate_repository! || validate_pipeline!
          end

          def break?
           @pipeline.errors.any? || @pipeline.persisted?
          end

          def allowed_to_trigger_pipeline?
            if current_user
              allowed_to_create?
            else # legacy triggers don't have a corresponding user
              !project.protected_for?(@pipeline.ref)
            end
          end

          def allowed_to_create?
            return unless can?(current_user, :create_pipeline, project)

            access = Gitlab::UserAccess.new(current_user, project: project)

            if branch?
              access.can_update_branch?(@pipeline.ref)
            elsif tag?
              access.can_create_tag?(@pipeline.ref)
            else
              true # Allow it for now and we'll reject when we check ref existence
            end
          end

          private

          def validate_project!
            unless project.builds_enabled?
              return error('Pipeline is disabled')
            end

            unless allowed_to_trigger_pipeline?
              if can?(current_user, :create_pipeline, project)
                return error("Insufficient permissions for protected ref '#{pipeline.ref}'")
              else
                return error('Insufficient permissions to create a new pipeline')
              end
            end
          end

          def validate_repository!
            unless branch? || tag?
              return error('Reference not found')
            end

            unless pipeline.sha
              return error('Commit not found')
            end
          end

          def validate_pipeline!
            unless @pipeline.config_processor
              unless @pipeline.ci_yaml_file
                return error("Missing #{@pipeline.ci_yaml_file_path} file")
              end

              if @command.save_incompleted && @pipeline.has_yaml_errors?
                @pipeline.drop
              end

              return error(@pipeline.yaml_errors)
            end

            unless @pipeline.has_stage_seeds?
              return error('No stages / jobs for this pipeline.')
            end
          end

          def branch?
            return @is_branch if defined?(@is_branch)

            @is_branch = project.repository.branch_exists?(pipeline.ref)
          end

          def tag?
            return @is_tag if defined?(@is_tag)

            @is_tag = project.repository.tag_exists?(pipeline.ref)
          end

          def error(message)
            pipeline.errors.add(:base, message)
          end
        end
      end
    end
  end
end
