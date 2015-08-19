class EmailRejectionMailer < ActionMailer::Base
  add_template_helper ApplicationHelper
  add_template_helper GitlabMarkdownHelper

  helper_method :current_user, :can?

  default from:     "#{Gitlab.config.gitlab.email_display_name} <#{Gitlab.config.gitlab.email_from}>"
  default reply_to: "#{Gitlab.config.gitlab.email_display_name} <#{Gitlab.config.gitlab.email_reply_to}>"

  def rejection(reason, original_raw, can_retry = false)
    @reason = reason
    @original_message = Mail::Message.new(original_raw)

    headers = {
      to: @original_message.from,
      subject: "[Rejected] #{@original_message.subject}"
    }

    headers['Message-ID'] = SecureRandom.hex
    headers['In-Reply-To'] = @original_message.message_id
    headers['References'] = @original_message.message_id

    headers['Reply-To'] = @original_message.to.first if can_retry

    mail(headers)
  end

  def current_user
    nil
  end

  def can?
    false
  end
end
