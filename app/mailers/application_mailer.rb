# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
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

  def mail_with_locale(headers = {}, &block)
    locale = recipient_locale headers

    Gitlab::I18n.with_locale(locale) do
      mail(headers, &block)
    end
  end

  def recipient_locale(headers = {})
    to = Array(headers[:to])
    locale = I18n.locale
    locale = preferred_language_by_email(to.first) if to.one?
    locale
  end

  def preferred_language_by_email(email)
    User.find_by_any_email(email)&.preferred_language || I18n.locale
  end
end
