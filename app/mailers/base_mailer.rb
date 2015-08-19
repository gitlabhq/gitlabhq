class EmailRejectionMailer < ActionMailer::Base
  add_template_helper ApplicationHelper
  add_template_helper GitlabMarkdownHelper

  attr_accessor :current_user
  helper_method :current_user, :can?

  default from:     Proc.new { default_sender_address.format }
  default reply_to: Proc.new { default_reply_to_address.format }

  def self.delay
    delay_for(2.seconds)
  end

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

  def can?
    Ability.abilities.allowed?(user, action, subject)
  end

  private

  def default_sender_address
    address = Mail::Address.new(Gitlab.config.gitlab.email_from)
    address.display_name = Gitlab.config.gitlab.email_display_name
    address
  end

  def default_reply_to_address
    address = Mail::Address.new(Gitlab.config.gitlab.email_reply_to)
    address.display_name = Gitlab.config.gitlab.email_display_name
    address
  end
end
