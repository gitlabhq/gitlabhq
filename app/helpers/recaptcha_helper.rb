# frozen_string_literal: true

module RecaptchaHelper
  def recaptcha_enabled?
    !!Gitlab::Recaptcha.enabled?
  end
  alias_method :show_recaptcha_sign_up?, :recaptcha_enabled?
end

RecaptchaHelper.prepend_mod
