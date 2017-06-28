module Members
  class ApproveAccessRequestService < BaseService
    include MembersHelper

    attr_accessor :source

    # source - The source object that respond to `#requesters` (i.g. project or group)
    # current_user - The user that performs the access request approval
    # params - A hash of parameters
    #   :user_id - User ID used to retrieve the access requester
    #   :id - Member ID used to retrieve the access requester
    #   :access_level - Optional access level set when the request is accepted
    def initialize(source, current_user, params = {})
      @source = source
      @current_user = current_user
      @params = params.slice(:user_id, :id, :access_level)
    end

    # opts - A hash of options
    #   :force - Bypass permission check: current_user can be nil in that case
    def execute(opts = {})
      condition = params[:user_id] ? { user_id: params[:user_id] } : { id: params[:id] }
      access_requester = source.requesters.find_by!(condition)

      raise Gitlab::Access::AccessDeniedError unless can_update_access_requester?(access_requester, opts)

      access_requester.access_level = params[:access_level] if params[:access_level]
      access_requester.accept_request

      access_requester
    end

    private

    def can_update_access_requester?(access_requester, opts = {})
      access_requester && (
        opts[:force] ||
        can?(current_user, action_member_permission(:update, access_requester), access_requester)
      )
    end
  end
end
