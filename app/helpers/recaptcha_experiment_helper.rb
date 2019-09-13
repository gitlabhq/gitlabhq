# frozen_string_literal: true

module RecaptchaExperimentHelper
  def show_recaptcha_sign_up?
    !!Gitlab::Recaptcha.enabled?
  end
end

RecaptchaExperimentHelper.prepend_if_ee('EE::RecaptchaExperimentHelper')
