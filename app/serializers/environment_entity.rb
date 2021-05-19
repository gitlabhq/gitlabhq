# frozen_string_literal: true

class EnvironmentEntity < Grape::Entity
  include RequestAwareEntity

  UNNECESSARY_ENTRIES_FOR_UPCOMING_DEPLOYMENT =
    %i[manual_actions scheduled_actions playable_build cluster].freeze

  expose :id

  expose :global_id do |environment|
    environment.to_global_id.to_s
  end

  expose :name
  expose :state
  expose :external_url
  expose :environment_type
  expose :name_without_type
  expose :last_deployment, using: DeploymentEntity
  expose :stop_action_available?, as: :has_stop_action
  expose :rollout_status, if: -> (*) { can_read_deploy_board? }, using: RolloutStatusEntity

  expose :upcoming_deployment, if: -> (environment) { environment.upcoming_deployment } do |environment, ops|
    DeploymentEntity.represent(environment.upcoming_deployment,
      ops.merge(except: UNNECESSARY_ENTRIES_FOR_UPCOMING_DEPLOYMENT))
  end

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

  expose :delete_path do |environment|
    environment_delete_path(environment)
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

  expose :logs_path, if: -> (*) { can_read_pod_logs? } do |environment|
    project_logs_path(environment.project, environment_name: environment.name)
  end

  expose :logs_api_path, if: -> (*) { can_read_pod_logs? } do |environment|
    if environment.elastic_stack_available?
      elasticsearch_project_logs_path(environment.project, environment_name: environment.name, format: :json)
    else
      k8s_project_logs_path(environment.project, environment_name: environment.name, format: :json)
    end
  end

  expose :enable_advanced_logs_querying, if: -> (*) { can_read_pod_logs? } do |environment|
    environment.elastic_stack_available?
  end

  expose :can_delete do |environment|
    can?(current_user, :destroy_environment, environment)
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

  def can_read_pod_logs?
    can?(current_user, :read_pod_logs, environment.project)
  end

  def can_read_deploy_board?
    can?(current_user, :read_deploy_board, environment.project)
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

EnvironmentEntity.prepend_mod_with('EnvironmentEntity')
