# frozen_string_literal: true

module Ci
  module JobTokenScope
    class RemoveGroupService < ::BaseService
      include EditScopeValidations

      def execute(target_group)
        validate_group_remove!(project, current_user)

        link = ::Ci::JobToken::GroupScopeLink
          .for_source_and_target(project, target_group)

        return ServiceResponse.error(message: 'Target group is not in the job token scope') unless link

        if link.destroy
          ServiceResponse.success(payload: link)
        else
          ServiceResponse.error(message: link.errors.full_messages.to_sentence, payload: { group_link: link })
        end
      rescue EditScopeValidations::ValidationError => e
        ServiceResponse.error(message: e.message, reason: :insufficient_permissions)
      end
    end
  end
end

Ci::JobTokenScope::RemoveGroupService.prepend_mod_with('Ci::JobTokenScope::RemoveGroupService')
