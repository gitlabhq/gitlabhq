# frozen_string_literal: true

module Ci
  module JobTokenScope
    class AddProjectService < ::BaseService
      include EditScopeValidations

      def execute(target_project, direction: :inbound)
        validate_edit!(project, target_project, current_user)

        link = allowlist(direction)
          .add!(target_project, user: current_user)

        ServiceResponse.success(payload: { project_link: link })

      rescue ActiveRecord::RecordNotUnique
        ServiceResponse.error(message: "Target project is already in the job token scope")
      rescue ActiveRecord::RecordInvalid => e
        ServiceResponse.error(message: e.message)
      rescue EditScopeValidations::ValidationError => e
        ServiceResponse.error(message: e.message)
      end

      private

      def allowlist(direction)
        Ci::JobToken::Allowlist.new(project, direction: direction)
      end
    end
  end
end
