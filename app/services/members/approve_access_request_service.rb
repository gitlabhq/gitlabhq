# frozen_string_literal: true

module Members
  class ApproveAccessRequestService < Members::BaseService
    def execute(access_requester, skip_authorization: false, skip_log_audit_event: false)
      validate_access!(access_requester) unless skip_authorization

      access_requester.access_level = params[:access_level] if params[:access_level]

      handle_request_acceptance(access_requester)

      after_execute(member: access_requester, skip_log_audit_event: skip_log_audit_event)

      success({ member: access_requester })
    end

    private

    def handle_request_acceptance(access_requester)
      limit_to_guest_if_billable_promotion_restricted(access_requester)
      access_requester.accept_request(current_user)
    end

    def after_execute(member:, skip_log_audit_event:)
      super

      resolve_access_request_todos(member)
    end

    def validate_access!(access_requester)
      raise Gitlab::Access::AccessDeniedError unless can_approve_access_requester?(access_requester)

      if approving_member_with_owner_access_level?(access_requester) &&
          cannot_assign_owner_responsibilities_to_member_in_project?(access_requester)
        raise Gitlab::Access::AccessDeniedError
      end
    end

    def limit_to_guest_if_billable_promotion_restricted(access_requester)
      # override in EE
    end

    def can_approve_access_requester?(access_requester)
      can?(current_user, :admin_member_access_request, access_requester.source) &&
        !role_too_high?(access_requester)
    end

    def role_too_high?(access_requester)
      access_requester.prevent_role_assignement?(current_user, params)
    end

    def approving_member_with_owner_access_level?(access_requester)
      access_level_value = params[:access_level] || access_requester.access_level

      access_level_value == Gitlab::Access::OWNER
    end
  end
end

Members::ApproveAccessRequestService.prepend_mod_with('Members::ApproveAccessRequestService')
