# Interceptor in lib/disable_email_interceptor.rb
unless Gitlab.config.gitlab.email_enabled
  ActionMailer::Base.register_interceptor(DisableEmailInterceptor)
  ActionMailer::Base.logger = nil
end
