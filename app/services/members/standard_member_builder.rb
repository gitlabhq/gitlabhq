# frozen_string_literal: true

module Members
  class StandardMemberBuilder
    def initialize(source, invitee, existing_members)
      @source = source
      @invitee = invitee
      @existing_members = existing_members
    end

    def execute
      find_or_initialize_member_by_user(invitee.id)
    end

    # previously_new_record? restricts this to newly-created memberships, so an update to an
    # already-existing membership doesn't destroy the invite. See
    # https://gitlab.com/gitlab-org/gitlab/-/issues/605830.
    def after_commit(member)
      return unless member.previously_new_record?

      destroy_pending_invite_for_email(invitee.email)
    end

    private

    attr_reader :source, :invitee, :existing_members

    def find_or_initialize_member_by_user(user_id)
      existing_members[user_id] || source.members_and_requesters.build(user_id: user_id)
    end

    def destroy_pending_invite_for_email(email)
      return if email.blank?

      source.members_and_requesters
        .invite
        .with_case_insensitive_invite_emails([email])
        .each { |invite| destroy_invite(invite) }
    end

    # The membership is already committed, so a failed cleanup must not fail the call or skip
    # the remaining invites; it is tracked instead.
    def destroy_invite(invite)
      invite.destroy!
    rescue ActiveRecord::RecordNotDestroyed => e
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e, member_id: invite.id, source_id: source.id)
    end
  end
end
