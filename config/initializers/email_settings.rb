Gitlab.config.outgoing_emails.tap do |c|
  Gitlab::Application.config.action_mailer.delivery_method = c.delivery_method
  ActionMailer::Base.smtp_settings = c.smtp_settings.symbolize_keys
  ActionMailer::Base.sendmail_settings = c.sendmail_settings.symbolize_keys
end
