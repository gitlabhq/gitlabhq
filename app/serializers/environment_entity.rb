# frozen_string_literal: true

class EnvironmentEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :name
  expose :state
  expose :external_url
  expose :environment_type
  expose :name_without_type
  expose :last_deployment, using: DeploymentEntity
  expose :stop_action_available?, as: :has_stop_action

  expose :metrics_path, if: -> (*) { environment.has_metrics? } do |environment|
    metrics_project_environment_path(environment.project, environment)
  end

  expose :environment_path do |environment|
    project_environment_path(environment.project, environment)
  end

  expose :stop_path do |environment|
    stop_project_environment_path(environment.project, environment)
  end

  expose :cancel_auto_stop_path, if: -> (*) { can_update_environment? } do |environment|
    cancel_auto_stop_project_environment_path(environment.project, environment)
  end

  expose :cluster_type, if: ->(environment, _) { cluster_platform_kubernetes? } do |environment|
    cluster.cluster_type
  end

  expose :terminal_path, if: ->(*) { environment.has_terminals? && can_access_terminal? } do |environment|
    terminal_project_environment_path(environment.project, environment)
  end

  expose :folder_path do |environment|
    folder_project_environments_path(environment.project, environment.folder_name)
  end

  expose :created_at, :updated_at
  expose :auto_stop_at, expose_nil: false

  expose :can_stop do |environment|
    environment.available? && can?(current_user, :stop_environment, environment)
  end

  private

  alias_method :environment, :object

  def current_user
    request.current_user
  end

  def can_access_terminal?
    can?(request.current_user, :create_environment_terminal, environment)
  end

  def can_update_environment?
    can?(current_user, :update_environment, environment)
  end

  def cluster_platform_kubernetes?
    deployment_platform && deployment_platform.is_a?(Clusters::Platforms::Kubernetes)
  end

  def deployment_platform
    environment.deployment_platform
  end

  def cluster
    deployment_platform.cluster
  end
end

EnvironmentEntity.prepend_if_ee('::EE::EnvironmentEntity')
