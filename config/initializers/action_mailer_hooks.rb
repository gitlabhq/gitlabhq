unless Gitlab.config.gitlab.email_enabled
  ActionMailer::Base.register_interceptor(::Gitlab::Email::Hook::DisableEmailInterceptor)
  ActionMailer::Base.logger = nil
end

ActionMailer::Base.register_interceptor(::Gitlab::Email::Hook::AdditionalHeadersInterceptor)
ActionMailer::Base.register_interceptor(::Gitlab::Email::Hook::EmailTemplateInterceptor)
