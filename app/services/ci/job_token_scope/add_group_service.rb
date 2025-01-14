# frozen_string_literal: true

module Ci
  module JobTokenScope
    class AddGroupService < ::BaseService
      include EditScopeValidations

      def execute(target_group, default_permissions: true, policies: [])
        validate_source_project_and_target_group_access!(project, target_group, current_user)

        link = allowlist
          .add_group!(target_group, default_permissions: default_permissions, policies: policies, user: current_user)

        ServiceResponse.success(payload: { group_link: link })

      rescue ActiveRecord::RecordNotUnique
        ServiceResponse.error(message: 'This group is already in the job token allowlist.')
      rescue ActiveRecord::RecordInvalid => e
        ServiceResponse.error(message: e.message)
      rescue EditScopeValidations::ValidationError => e
        ServiceResponse.error(message: e.message, reason: :insufficient_permissions)
      end

      private

      def allowlist
        Ci::JobToken::Allowlist.new(project)
      end
    end
  end
end

Ci::JobTokenScope::AddGroupService.prepend_mod_with('Ci::JobTokenScope::AddGroupService')
