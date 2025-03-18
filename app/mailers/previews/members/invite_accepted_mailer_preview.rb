# frozen_string_literal: true

module Members
  class InviteAcceptedMailerPreview < ActionMailer::Preview
    def email
      Members::InviteAcceptedMailer.with(member: member).email.message # rubocop:disable CodeReuse/ActiveRecord -- false positive
    end

    private

    def member
      Member.non_invite.non_request.with_created_by.last
    end
  end
end
