class DeviseMailer < Devise::Mailer
  default from: "#{Gitlab.config.gitlab.email_display_name} <#{Gitlab.config.gitlab.email_from}>"
  default reply_to: Gitlab.config.gitlab.email_reply_to
end
