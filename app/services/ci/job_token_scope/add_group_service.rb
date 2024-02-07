# frozen_string_literal: true

module Ci
  module JobTokenScope
    class AddGroupService < ::BaseService
      include EditScopeValidations

      def execute(target_group)
        validate_group_add!(project, target_group, current_user)

        link = allowlist
          .add_group!(target_group, user: current_user)

        ServiceResponse.success(payload: { group_link: link })

      rescue ActiveRecord::RecordNotUnique
        ServiceResponse.error(message: 'Target group is already in the job token scope')
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
