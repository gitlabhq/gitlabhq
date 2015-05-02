class DeviseMailer < Devise::Mailer
  default from: "GitLab <#{Gitlab.config.gitlab.email_from}>"
  default reply_to: Gitlab.config.gitlab.email_reply_to
end
