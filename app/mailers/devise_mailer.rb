class DeviseMailer < Devise::Mailer
  default from: "#{Gitlab.config.outgoing_emails.display_name} <#{Gitlab.config.outgoing_emails.from}>"
  default reply_to: Gitlab.config.outgoing_emails.reply_to
end
