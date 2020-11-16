# frozen_string_literal: true

module RecaptchaHelper
  def show_recaptcha_sign_up?
    !!Gitlab::Recaptcha.enabled?
  end
end
