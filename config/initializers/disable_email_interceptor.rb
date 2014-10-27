# Interceptor in lib/disable_email_interceptor.rb
ActionMailer::Base.register_interceptor(DisableEmailInterceptor) unless Gitlab.config.gitlab.email_enabled
