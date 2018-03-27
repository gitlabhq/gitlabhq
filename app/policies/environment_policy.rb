class EnvironmentPolicy < BasePolicy
  delegate { @subject.project }

  condition(:stop_action_allowed) do
    @subject.stop_action? && can?(:update_build, @subject.stop_action)
  end

  rule { can?(:create_deployment) & stop_action_allowed }.enable :stop_environment
end
