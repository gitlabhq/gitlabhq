# frozen_string_literal: true

module Members
  class InviteMemberBuilder < StandardMemberBuilder
    def execute
      if user_by_email
        find_or_initialize_member_by_user(user_by_email.id)
      else
        source.members_and_requesters.find_or_initialize_by(invite_email: invitee) # rubocop:disable CodeReuse/ActiveRecord
      end
    end

    private

    def user_by_email
      source.users_by_emails([invitee])[invitee]
    end
  end
end
