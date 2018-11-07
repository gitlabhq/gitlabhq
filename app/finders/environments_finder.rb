# frozen_string_literal: true

class EnvironmentsFinder
  attr_reader :project, :current_user, :params

  def initialize(project, current_user, params = {})
    @project, @current_user, @params = project, current_user, params
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def execute
    deployments = project.deployments
    deployments =
      if ref
        deployments_query = params[:with_tags] ? 'ref = :ref OR tag IS TRUE' : 'ref = :ref'
        deployments.where(deployments_query, ref: ref.to_s)
      elsif commit
        deployments.where(sha: commit.sha)
      else
        deployments.none
      end

    environment_ids = deployments
      .group(:environment_id)
      .select(:environment_id)

    environments = project.environments.available
      .where(id: environment_ids).order_by_last_deployed_at.to_a

    environments.select! do |environment|
      Ability.allowed?(current_user, :read_environment, environment)
    end

    if ref && commit
      environments.select! do |environment|
        environment.includes_commit?(commit)
      end
    end

    if ref && params[:recently_updated]
      environments.select! do |environment|
        environment.recently_updated_on_branch?(ref)
      end
    end

    environments
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def ref
    params[:ref].try(:to_s)
  end

  def commit
    params[:commit]
  end
end
