# frozen_string_literal: true

module Ci
  module JobTokenScope
    class AddGroupOrProjectService < ::BaseService
      include EditScopeValidations

      def execute(target, default_permissions: true, policies: [])
        validate_target_exists!(target)

        if target.is_a?(::Group)
          ::Ci::JobTokenScope::AddGroupService.new(project, current_user).execute(target,
            default_permissions: default_permissions, policies: policies)
        else
          ::Ci::JobTokenScope::AddProjectService.new(project, current_user).execute(target,
            default_permissions: default_permissions, policies: policies)
        end

      rescue EditScopeValidations::NotFoundError => e
        ServiceResponse.error(message: e.message, reason: :not_found)
      end
    end
  end
end
