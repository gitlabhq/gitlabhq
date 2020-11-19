# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  default from: "#{Gitlab.config.gitlab.email_display_name} <#{Gitlab.config.gitlab.email_from}>"
  default reply_to: Gitlab.config.gitlab.email_reply_to

  layout 'mailer/devise'

  helper EmailsHelper
  helper ApplicationHelper

  def password_change_by_admin(record, opts = {})
    devise_mail(record, :password_change_by_admin, opts)
  end

  def user_admin_approval(record, opts = {})
    devise_mail(record, :user_admin_approval, opts)
  end

  protected

  def subject_for(key)
    subject = [super]
    subject << Gitlab.config.gitlab.email_subject_suffix if Gitlab.config.gitlab.email_subject_suffix.present?

    subject.join(' | ')
  end
end
