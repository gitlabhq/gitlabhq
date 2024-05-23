# frozen_string_literal: true

module Members
  class InviteMemberBuilder < StandardMemberBuilder
    def execute
      if user_by_email
        find_or_initialize_member_by_user(user_by_email.id)
      else
        source.members_and_requesters.find_or_initialize_by(invite_email: invitee).tap do |record| # rubocop:disable CodeReuse/ActiveRecord -- TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/462165
          # We do not want to cause misses for existing records as the invite process is also sometimes used
          # as a way to update existing invites.
          record.invite_email = invitee.downcase if record.new_record?
        end
      end
    end

    private

    def user_by_email
      # Since we cache the user lookups for the emails in lowercase format, we
      # now need to look them up the same way to ensure we don't get cache misses.
      source.users_by_emails([invitee.downcase])[invitee.downcase]
    end
  end
end
