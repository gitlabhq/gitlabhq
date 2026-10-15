# frozen_string_literal: true

module Members
  class AcceptInviteService < Members::BaseService
    def initialize(...)
      super

      @member = @params[:member]
    end

    def execute
      return ServiceResponse.error(message: _("The invitation could not be accepted.")) unless accept_invite!

      publish_accepted_invite_event
      ServiceResponse.success
    end

    private

    attr_reader :member
    alias_method :user, :current_user

    def accept_invite!
      return unless user_matches_invite?

      member.accept_invite!(user)
    end

    def user_matches_invite?
      user.verified_email?(member.invite_email)
    end

    def publish_accepted_invite_event
      Gitlab::EventStore.publish(
        Members::AcceptedInviteCloudEvent.build(
          source: member.source,
          current_user: user,
          user_id: user.id,
          member_id: member.id
        )
      )
    end
  end
end
