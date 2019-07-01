# frozen_string_literal: true

module OnboardingExperimentHelper
  def allow_access_to_onboarding?
    ::Gitlab.com? && Feature.enabled?(:user_onboarding)
  end
end
