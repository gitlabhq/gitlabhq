module Members
  class ApproveAccessRequestService < Members::BaseService
    prepend EE::Members::ApproveAccessRequestService

    # opts - A hash of options
    #   :ldap - The call is from a LDAP sync: current_user can be nil in that case
    def execute(access_requester, opts = {})
      raise Gitlab::Access::AccessDeniedError unless can_update_access_requester?(access_requester, opts[:ldap])

      access_requester.access_level = params[:access_level] if params[:access_level]
      access_requester.accept_request

      after_execute(member: access_requester, **opts)

      access_requester
    end

    private

    def can_update_access_requester?(access_requester, ldap)
      access_requester && (
        ldap ||
        can?(current_user, update_member_permission(access_requester), access_requester)
      )
    end
  end
end
