# frozen_string_literal: true

class EnvironmentEntity < Grape::Entity
  include RequestAwareEntity
  prepend ::EE::EnvironmentEntity

  expose :id
  expose :name
  expose :state
  expose :external_url
  expose :environment_type
  expose :last_deployment, using: DeploymentEntity
  expose :stop_action_available?, as: :has_stop_action
  expose :rollout_status, if: -> (*) { can_read_deploy_board? }, using: RolloutStatusEntity

  expose :metrics_path, if: -> (*) { environment.has_metrics? } do |environment|
    metrics_project_environment_path(environment.project, environment)
  end

  expose :environment_path do |environment|
    project_environment_path(environment.project, environment)
  end

  expose :stop_path do |environment|
    stop_project_environment_path(environment.project, environment)
  end

  expose :terminal_path, if: ->(*) { environment.has_terminals? && can_access_terminal? } do |environment|
    terminal_project_environment_path(environment.project, environment)
  end

  expose :folder_path do |environment|
    folder_project_environments_path(environment.project, environment.folder_name)
  end

  expose :created_at, :updated_at

  expose :can_stop do |environment|
    environment.available? && can?(current_user, :stop_environment, environment)
  end

  private

  alias_method :environment, :object

  def current_user
    request.current_user
  end

  def can_read_deploy_board?
    can?(current_user, :read_deploy_board, environment.project)
  end

  def can_access_terminal?
    can?(request.current_user, :create_environment_terminal, environment)
  end
end
