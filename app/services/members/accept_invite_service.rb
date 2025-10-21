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
        Members::AcceptedInviteEvent.new(data: {
          member_id: member.id,
          source_id: member.source_id,
          source_type: member.source_type,
          user_id: user.id
        })
      )
    end
  end
end
