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

              unless allowed_to_create_pipeline?
                return error('Insufficient permissions to create a new pipeline')
              end

              unless allowed_to_write_ref?
                error("You do not have sufficient permission to run a pipeline on '#{command.ref}'. Please select a different branch or contact your administrator for assistance. <a href=https://docs.gitlab.com/ee/ci/pipelines/#pipeline-security-on-protected-branches>Learn more</a>".html_safe)
              end
            end

            def break?
              @pipeline.errors.any?
            end

            private

            def allowed_to_create_pipeline?
              can?(current_user, :create_pipeline, project)
            end

            def allowed_to_write_ref?
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
          end
        end
      end
    end
  end
end

Gitlab::Ci::Pipeline::Chain::Validate::Abilities.prepend_mod_with('Gitlab::Ci::Pipeline::Chain::Validate::Abilities')
