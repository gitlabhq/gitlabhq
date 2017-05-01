class EnvironmentPolicy < BasePolicy

  alias_method :environment, :subject

  def rules
    delegate! environment.project

    if environment.stop_action?
      delegate! environment.stop_action
    end

    if can?(:create_deployment) && can?(:play_build)
      can! :stop_environment
    end
  end
end
