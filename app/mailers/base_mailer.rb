class BaseMailer < ActionMailer::Base
  add_template_helper ApplicationHelper
  add_template_helper GitlabMarkdownHelper

  attr_accessor :current_user
  helper_method :current_user, :can?

  default from:     Proc.new { default_sender_address.format }
  default reply_to: Proc.new { default_reply_to_address.format }

  def self.delay
    delay_for(2.seconds)
  end

  def can?
    Ability.abilities.allowed?(current_user, action, subject)
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
