# frozen_string_literal: true

module Ci
  module JobTokenScope
    class RemoveProjectService < ::BaseService
      include EditScopeValidations

      def execute(target_project)
        validate_edit!(project, target_project, current_user)

        if project == target_project
          return ServiceResponse.error(message: "Source project cannot be removed from the job token scope")
        end

        link = ::Ci::JobToken::ProjectScopeLink.for_source_and_target(project, target_project)

        unless link
          return ServiceResponse.error(message: "Target project is not in the job token scope")
        end

        if link.destroy
          ServiceResponse.success
        else
          ServiceResponse.error(message: link.errors.full_messages.to_sentence, payload: { project_link: link })
        end
      rescue EditScopeValidations::ValidationError => e
        ServiceResponse.error(message: e.message)
      end
    end
  end
end
