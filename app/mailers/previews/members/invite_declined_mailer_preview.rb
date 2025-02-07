# frozen_string_literal: true

module Members
  class InviteDeclinedMailerPreview < ActionMailer::Preview
    def email
      Members::InviteDeclinedMailer.with(member: member).email.message # rubocop:disable CodeReuse/ActiveRecord -- false positive
    end

    private

    def member
      Member.with_created_by.connected_to_user.last
    end
  end
end
