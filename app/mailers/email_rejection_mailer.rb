# frozen_string_literal: true

class EmailRejectionMailer < ApplicationMailer
  layout 'empty_mailer'

  helper EmailsHelper

  def rejection(reason, original_raw, can_retry = false)
    @reason = reason
    @original_message = Mail::Message.new(original_raw)

    return unless @original_message.from

    headers = {
      to: @original_message.from,
      subject: "[Rejected] #{@original_message.subject}"
    }

    headers['Message-ID'] = "<#{SecureRandom.hex}@#{Gitlab.config.gitlab.host}>"
    headers['In-Reply-To'] = @original_message.message_id
    headers['References'] = @original_message.message_id

    headers['Reply-To'] = @original_message.to.first if can_retry

    mail_with_locale(headers)
  end
end
