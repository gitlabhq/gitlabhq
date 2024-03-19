# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  default from: "#{Gitlab.config.gitlab.email_display_name} <#{Gitlab.config.gitlab.email_from}>"
  default reply_to: Gitlab.config.gitlab.email_reply_to

  layout 'mailer/devise'

  helper EmailsHelper
  helper ApplicationHelper
  helper RegistrationsHelper
  include Gitlab::Email::SingleRecipientValidator

  # Override devise_mail so that all emails, not just those redefined
  # here, can only be sent to a single to: address.
  def devise_mail(record, action, opts = {}, &block)
    validate_single_recipient_in_opts!(opts)
    super
  end

  def password_change_by_admin(record, opts = {})
    devise_mail(record, :password_change_by_admin, opts)
  end

  def user_admin_approval(record, opts = {})
    devise_mail(record, :user_admin_approval, opts)
  end

  def reset_password_instructions(record, token, opts = {})
    headers['X-Mailgun-Suppressions-Bypass'] = 'true'
    super
  end

  def email_changed(record, opts = {})
    if Gitlab.com?
      devise_mail(record, :email_changed_gitlab_com, opts)
    else
      devise_mail(record, :email_changed, opts)
    end
  end

  protected

  def subject_for(key)
    subject = [super]
    subject << Gitlab.config.gitlab.email_subject_suffix if Gitlab.config.gitlab.email_subject_suffix.present?

    subject.join(' | ')
  end
end
