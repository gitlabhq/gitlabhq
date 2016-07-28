module Members
  class ApproveAccessRequestService < BaseService
    include MembersHelper

    attr_accessor :source

    def initialize(source, current_user, params = {})
      @source = source
      @current_user = current_user
      @params = params
    end

    def execute
      access_requester = source.requesters.find_by!(user_id: params[:user_id])

      raise Gitlab::Access::AccessDeniedError if cannot_update_access_requester?(access_requester)

      access_requester.access_level = params[:access_level] if params[:access_level]
      access_requester.accept_request

      access_requester
    end

    private

    def cannot_update_access_requester?(access_requester)
      !access_requester || !can?(current_user, action_member_permission(:update, access_requester), access_requester)
    end
  end
end
