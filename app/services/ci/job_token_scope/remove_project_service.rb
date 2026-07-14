# frozen_string_literal: true

module Ci
  module JobTokenScope
    class RemoveProjectService < ::BaseService
      include EditScopeValidations

      TARGET_NOT_IN_SCOPE = "Target project is not in the job token scope"
      SOURCE_CANNOT_BE_REMOVED = "Source project cannot be removed from the job token scope"

      def execute(target_project, direction)
        validate_group_remove!(project, current_user)

        if project == target_project
          return ServiceResponse.error(message: SOURCE_CANNOT_BE_REMOVED)
        end

        link = ::Ci::JobToken::ProjectScopeLink
          .with_access_direction(direction)
          .for_source_and_target(project, target_project)

        unless link
          return ServiceResponse.error(message: TARGET_NOT_IN_SCOPE)
        end

        if link.destroy
          ServiceResponse.success(payload: link)
        else
          ServiceResponse.error(message: link.errors.full_messages.to_sentence, payload: { project_link: link })
        end
      rescue EditScopeValidations::ValidationError => e
        ServiceResponse.error(message: e.message, reason: :insufficient_permissions)
      end
    end
  end
end

Ci::JobTokenScope::RemoveProjectService.prepend_mod_with('Ci::JobTokenScope::RemoveProjectService')
