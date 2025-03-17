# frozen_string_literal: true

module Members
  class AccessRequestedMailerPreview < ActionMailer::Preview
    def email
      Members::AccessRequestedMailer.with(member: member, recipient: recipient).email.message # rubocop:disable CodeReuse/ActiveRecord -- false positive
    end

    private

    def member
      Member.non_invite.non_request.last
    end

    def recipient
      User.last
    end
  end
end
