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

  # This method will eventually take the place of `#execute` as an
  # efficient way to get relevant environment entries.
  # Currently, `#execute` method has a serious technical debt and
  # we will likely rework on it in the future.
  # See more https://gitlab.com/gitlab-org/gitlab-ce/issues/63381
  def find
    environments = project.environments
    environments = by_name(environments)
    environments = by_search(environments)

    environments
  end

  private

  def ref
    params[:ref].try(:to_s)
  end

  def commit
    params[:commit]
  end

  def by_name(environments)
    if params[:name].present?
      environments.for_name(params[:name])
    else
      environments
    end
  end

  def by_search(environments)
    if params[:search].present?
      environments.for_name_like(params[:search], limit: nil)
    else
      environments
    end
  end
end
