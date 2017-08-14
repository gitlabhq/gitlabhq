module Members
  class ApproveAccessRequestService < BaseService
    include MembersHelper
    include Gitlab::Access

    DEFAULT_ACCESS_LEVEL = Gitlab::Access::DEVELOPER

    attr_accessor :source, :access_requester, :current_user, :access_level

    # source - The source object that respond to `#access_requests` (i.g. project or group)
    # access_requester - The user who requested access
    # current_user - The user that performs the access request approval
    # access_level - Optional access level set when the request is accepted
    def initialize(source, access_requester, current_user, access_level = DEFAULT_ACCESS_LEVEL)
      @source = source
      @access_requester = access_requester
      @current_user = current_user
      @access_level = access_level
    end

    attr_accessor :source

    # opts - A hash of options
    #   :force - Bypass permission check: current_user can be nil in that case
    def execute(opts = {})
      access_request = source.access_requests.where(user: access_requester).take!

      raise Gitlab::Access::AccessDeniedError unless can_update_access_request?(access_request, opts)

      member = Member.add_user(source, access_requester, access_level, current_user: current_user)

      raise 'Failed to create member from access request' unless member.persisted?

      # Member destroys AccessRequests in after_create.

      member
    end

    private

    def can_update_access_request?(access_request, opts = {})
      access_request && (
        opts[:force] ||
        can?(current_user, action_access_request_permission(:update, access_request), access_request)
      )
    end
  end
end
