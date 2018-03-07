module Members
  class ApproveAccessRequestService < Members::BaseService
    def execute(access_requester, skip_authorization: false, skip_log_audit_event: false)
      raise Gitlab::Access::AccessDeniedError unless skip_authorization || can_update_access_requester?(access_requester)

      access_requester.access_level = params[:access_level] if params[:access_level]
      access_requester.accept_request

      after_execute(member: access_requester, skip_log_audit_event: skip_log_audit_event)

      access_requester
    end

    private

    def can_update_access_requester?(access_requester)
      can?(current_user, update_member_permission(access_requester), access_requester)
    end
  end
end
