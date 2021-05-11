# frozen_string_literal: true

class EnvironmentPolicy < BasePolicy
  delegate { @subject.project }

  condition(:stop_with_deployment_allowed) do
    @subject.stop_action_available? &&
      can?(:create_deployment) && can?(:update_build, @subject.stop_action)
  end

  condition(:stop_with_update_allowed) do
    !@subject.stop_action_available? && can?(:update_environment, @subject)
  end

  condition(:stopped) do
    @subject.stopped?
  end

  rule { stop_with_deployment_allowed | stop_with_update_allowed }.enable :stop_environment

  rule { ~stopped }.prevent(:destroy_environment)
end

EnvironmentPolicy.prepend_mod_with('EnvironmentPolicy')
