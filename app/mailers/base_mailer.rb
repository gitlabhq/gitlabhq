class BaseMailer < ActionMailer::Base
  around_action :render_with_default_locale

  helper ApplicationHelper
  helper MarkupHelper

  attr_accessor :current_user
  helper_method :current_user, :can?

  default from:     proc { default_sender_address.format }
  default reply_to: proc { default_reply_to_address.format }

  def can?
    Ability.allowed?(current_user, action, subject)
  end

  private

  def render_with_default_locale(&block)
    Gitlab::I18n.with_default_locale(&block)
  end

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
