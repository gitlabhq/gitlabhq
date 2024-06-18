# frozen_string_literal: true

module Members
  class InviteMailerPreview < ActionMailer::Preview
    def initial_email
      Members::InviteMailer.initial_email(Member.last, '1234').message
    end
  end
end
