class EnvironmentPolicy < BasePolicy
  alias_method :environment, :subject

  def rules
    delegate! environment.project

    if can?(:create_deployment) && environment.stop_action?
      can! :stop_environment if can_play_stop_action?
    end
  end

  private

  def can_play_stop_action?
    Ability.allowed?(user, :update_build, environment.stop_action)
  end
end
