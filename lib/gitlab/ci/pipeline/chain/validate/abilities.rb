# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Validate
          class Abilities < Chain::Base
            include Gitlab::Allowable
            include Chain::Helpers

            def perform!
              if project.pending_delete?
                return error('Project is deleted!')
              end

              unless project.builds_enabled?
                return error('Pipelines are disabled!')
              end

              if project.import_in_progress?
                return error('You cannot run pipelines before project import is complete.')
              end

              unless allowed_to_create_pipeline?
                return error('Insufficient permissions to create a new pipeline')
              end

              unless allowed_to_run_pipeline?
                error("You do not have sufficient permission to run a pipeline on '#{command.ref}'. Please select a different branch or contact your administrator for assistance.")
              end
            end

            def break?
              @pipeline.errors.any?
            end

            private

            def allowed_to_create_pipeline?
              can?(current_user, :create_pipeline, project)
            end

            def allowed_to_run_pipeline?
              allowed_to_write_ref?
            end

            def allowed_to_write_ref?
              return allowed_to_write_ref_new? if Feature.enabled?(:allow_merge_request_pipelines_from_fork, project)

              access = Gitlab::UserAccess.new(current_user, container: project)

              if @command.branch_exists?
                access.can_update_branch?(@command.ref)
              elsif @command.tag_exists?
                access.can_create_tag?(@command.ref)
              elsif @command.merge_request_ref_exists?
                access.can_update_branch?(@command.merge_request.source_branch)
              else
                true # Allow it for now and we'll reject when we check ref existence
              end
            end

            def allowed_to_write_ref_new?
              access = Gitlab::UserAccess.new(current_user, container: project)

              # This scenarios is when we have a MR from fork but the user has permissions to run
              # a pipeline on the target project. In this case the pipeline is created using the MR ref.
              # We skip the check because MR refs are created internally and there is no ref protection rules
              # applicable to them.
              # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/378945
              if @command.merge_request_ref_exists? && @command.merge_request.for_fork?
                true
              elsif @command.merge_request_ref_exists? && @command.merge_request.for_same_project?
                access.can_update_branch?(@command.merge_request.source_branch)
              elsif @command.branch_exists?
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

Gitlab::Ci::Pipeline::Chain::Validate::Abilities.prepend_mod_with('Gitlab::Ci::Pipeline::Chain::Validate::Abilities')
