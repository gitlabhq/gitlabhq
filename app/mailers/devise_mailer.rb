class DeviseMailer < Devise::Mailer
  default from: "#{Gitlab.config.gitlab.email_display_name} <#{Gitlab.config.gitlab.email_from}>"
  default reply_to: Gitlab.config.gitlab.email_reply_to

  layout 'devise_mailer'

  protected

  def subject_for(key)
    subject = super
    subject << " | #{Gitlab.config.gitlab.email_subject_suffix}" if Gitlab.config.gitlab.email_subject_suffix.length > 0
    subject
  end
end
