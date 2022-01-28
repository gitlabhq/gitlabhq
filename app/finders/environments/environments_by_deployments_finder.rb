# frozen_string_literal: true

module Environments
  class EnvironmentsByDeploymentsFinder
    attr_reader :project, :current_user, :params

    def initialize(project, current_user, params = {})
      @project = project
      @current_user = current_user
      @params = params
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def execute
      deployments =
        if ref
          Deployment.where(ref: ref.to_s)
        elsif sha
          Deployment.where(sha: sha)
        else
          Deployment.none
        end

      environments = project.environments.available
                       .where('EXISTS (?)', deployments.where('environment_id = environments.id'))

      if params[:find_latest]
        find_one(environments.order_by_last_deployed_at_desc)
      else
        find_all(environments.order_by_last_deployed_at.to_a)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

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
      return false if ref && sha && !environment.includes_commit?(sha)

      true
    end

    def ref
      params[:ref].try(:to_s)
    end

    def sha
      params[:sha] || params[:commit]&.id
    end
  end
end
