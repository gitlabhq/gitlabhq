# frozen_string_literal: true

class EmailRejectionMailerPreview < ActionMailer::Preview
  def rejection
    EmailRejectionMailer.rejection("some rejection reason", "From: someone@example.com\nraw email here").message
  end
end
