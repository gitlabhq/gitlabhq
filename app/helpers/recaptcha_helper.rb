# frozen_string_literal: true

module RecaptchaHelper
  def recaptcha_enabled?
    return false if gitlab_qa?

    !!Gitlab::Recaptcha.enabled?
  end
  alias_method :show_recaptcha_sign_up?, :recaptcha_enabled?

  def recaptcha_enabled_on_login?
    return false if gitlab_qa?

    Gitlab::Recaptcha.enabled_on_login?
  end

  private

  def gitlab_qa?
    return false unless Gitlab.com?
    return false unless request.user_agent.present?
    return false unless Gitlab::Environment.qa_user_agent.present?

    ActiveSupport::SecurityUtils.secure_compare(request.user_agent, Gitlab::Environment.qa_user_agent)
  end
end

RecaptchaHelper.prepend_mod
