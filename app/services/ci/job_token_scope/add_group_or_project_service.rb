# frozen_string_literal: true

module Ci
  module JobTokenScope
    class AddGroupOrProjectService < ::BaseService
      include EditScopeValidations

      def execute(target, policies: [])
        validate_target_exists!(target)

        if target.is_a?(::Group)
          ::Ci::JobTokenScope::AddGroupService.new(project, current_user).execute(target, policies: policies)
        else
          ::Ci::JobTokenScope::AddProjectService.new(project, current_user).execute(target, policies: policies)
        end

      rescue EditScopeValidations::NotFoundError => e
        ServiceResponse.error(message: e.message, reason: :not_found)
      end
    end
  end
end
