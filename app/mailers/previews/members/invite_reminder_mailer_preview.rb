# frozen_string_literal: true

module Members
  class InviteReminderMailerPreview < ActionMailer::Preview
    def first_reminder_email
      Members::InviteReminderMailer.email(member, '1234', 0).message
    end

    def second_reminder_email
      Members::InviteReminderMailer.email(member, '1234', 1).message
    end

    def last_reminder_email
      Members::InviteReminderMailer.email(member, '1234', 2).message
    end

    private

    def member
      Member.not_accepted_invitations.with_created_by.last
    end
  end
end
