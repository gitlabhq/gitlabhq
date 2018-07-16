ActionMailer::Base
  .register_interceptor(::Gitlab::Email::Hook::AdditionalHeadersInterceptor)
