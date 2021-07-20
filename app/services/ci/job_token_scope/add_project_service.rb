# frozen_string_literal: true

module Ci
  module JobTokenScope
    class AddProjectService < ::BaseService
      include EditScopeValidations

      def execute(target_project)
        validate_edit!(project, target_project, current_user)

        link = add_project!(target_project)
        ServiceResponse.success(payload: { project_link: link })

      rescue ActiveRecord::RecordNotUnique
        ServiceResponse.error(message: "Target project is already in the job token scope")
      rescue ActiveRecord::RecordInvalid => e
        ServiceResponse.error(message: e.message)
      rescue EditScopeValidations::ValidationError => e
        ServiceResponse.error(message: e.message)
      end

      def add_project!(target_project)
        ::Ci::JobToken::ProjectScopeLink.create!(
          source_project: project,
          target_project: target_project,
          added_by: current_user
        )
      end
    end
  end
end
