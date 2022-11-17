# frozen_string_literal: true

module RecaptchaHelper
  def recaptcha_enabled?
    return false if Gitlab::Qa.request?(request.user_agent)

    !!Gitlab::Recaptcha.enabled?
  end
  alias_method :show_recaptcha_sign_up?, :recaptcha_enabled?

  def recaptcha_enabled_on_login?
    return false if Gitlab::Qa.request?(request.user_agent)

    Gitlab::Recaptcha.enabled_on_login?
  end
end

RecaptchaHelper.prepend_mod
