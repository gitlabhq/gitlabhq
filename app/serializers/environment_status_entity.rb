# frozen_string_literal: true

class EnvironmentStatusEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :name
  expose :status

  expose :url do |es|
    project_environment_path(es.project, es.environment)
  end

  expose :stop_url, if: ->(*) { can_stop_environment? } do |es|
    stop_project_environment_path(es.project, es.environment)
  end

  expose :retry_url, if: ->(*) { can_rollback_environment? } do |es|
    retry_project_job_path(es.project, es.deployment.deployable)
  end

  expose :external_url do |es|
    es.environment.external_url
  end

  expose :external_url_formatted do |es|
    es.environment.formatted_external_url
  end

  expose :deployed_at

  expose :deployed_at_formatted do |es|
    es.deployment.try(:formatted_deployment_time)
  end

  expose :deployment, as: :details do |es, options|
    DeploymentEntity.represent(es.deployment, options.merge(project: es.project, only: [:playable_job]))
  end

  expose :environment_available do |es|
    es.environment.available?
  end

  expose :changes

  private

  def environment
    object.environment
  end

  def project
    object.environment.project
  end

  def current_user
    request.current_user
  end

  def can_read_environment?
    can?(current_user, :read_environment, environment)
  end

  def can_stop_environment?
    can?(current_user, :stop_environment, environment)
  end

  def can_rollback_environment?
    object.deployable && can?(current_user, :play_job, object.deployable)
  end
end
