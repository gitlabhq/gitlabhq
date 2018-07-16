unless Gitlab.config.gitlab.email_enabled
  ActionMailer::Base.register_interceptor(::Gitlab::Email::Hook::DisableEmailInterceptor)
  ActionMailer::Base.logger = nil
end

ActionMailer::Base.register_interceptors(
  ::Gitlab::Email::Hook::AdditionalHeadersInterceptor,
  ::Gitlab::Email::Hook::EmailTemplateInterceptor,
  ::Gitlab::Email::Hook::DeliveryMetricsObserver
)

ActionMailer::Base.register_observer(::Gitlab::Email::Hook::DeliveryMetricsObserver)
