module Members
  class AuthorizedDestroyService < BaseService
    attr_accessor :member, :user

    def initialize(member, user = nil)
      @member, @user = member, user
    end

    def execute
      return false if member.is_a?(GroupMember) && member.source.last_owner?(member.user)

      member.destroy

      if member.request? && member.user != user
        notification_service.decline_access_request(member)
      end
    end
  end
end
