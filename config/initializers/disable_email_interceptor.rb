# Interceptor in lib/disable_email_interceptor.rb
unless Gitlab.config.outgoing_emails.enabled
  ActionMailer::Base.register_interceptor(DisableEmailInterceptor)
end
