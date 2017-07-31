module Members
  class DestroyAccessRequestService < BaseService
    include MembersHelper

    attr_accessor :source, :access_requester, :current_user

    def initialize(source, access_requester, current_user)
      @source = source
      @access_requester = access_requester
      @current_user = current_user
    end

    def execute
      access_request_scope = source.access_requests.where(user: access_requester)

      access_request = access_request_scope.take!

      raise Gitlab::Access::AccessDeniedError unless can_destroy_access_request?(access_request)

      # Why not a simple find then destroy?
      #
      #   ActiveRecord does not like not having a primary key, and I don't have
      #   enough reason to add a composite keys gem yet (which apparently is
      #   rewritten for every major Rails version).
      access_request_scope.delete_all

      if current_user != access_requester
        notification_service.decline_access_request(access_request)
      end
    end

    private

    def can_destroy_access_request?(access_request)
      access_request && can?(current_user, action_access_request_permission(:destroy, access_request), access_request)
    end
  end
end
