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
      .where(id: environment_ids)

    if params[:find_latest]
      find_one(environments.order_by_last_deployed_at_desc)
    else
      find_all(environments.order_by_last_deployed_at.to_a)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # This method will eventually take the place of `#execute` as an
  # efficient way to get relevant environment entries.
  # Currently, `#execute` method has a serious technical debt and
  # we will likely rework on it in the future.
  # See more https://gitlab.com/gitlab-org/gitlab-foss/issues/63381
  def find
    environments = project.environments
    environments = by_name(environments)
    environments = by_search(environments)

    environments
  end

  private

  def find_one(environments)
    [environments.find { |environment| valid_environment?(environment) }].compact
  end

  def find_all(environments)
    environments.select { |environment| valid_environment?(environment) }
  end

  def valid_environment?(environment)
    # Go in order of cost: SQL calls are cheaper than Gitaly calls
    return false unless Ability.allowed?(current_user, :read_environment, environment)

    return false if ref && params[:recently_updated] && !environment.recently_updated_on_branch?(ref)
    return false if ref && commit && !environment.includes_commit?(commit)

    true
  end

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
