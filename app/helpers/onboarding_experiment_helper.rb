# frozen_string_literal: true

module OnboardingExperimentHelper
  def allow_access_to_onboarding?
    ::Gitlab.dev_env_or_com? && Feature.enabled?(:user_onboarding)
  end
end

OnboardingExperimentHelper.prepend_if_ee('EE::OnboardingExperimentHelper')
