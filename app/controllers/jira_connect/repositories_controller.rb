# frozen_string_literal: true

module JiraConnect
  class RepositoriesController < JiraConnect::ApplicationController
    feature_category :integrations

    def search
      repositories = available_repositories.by_name(search_query).page(query_params[:page]).per(query_params[:limit])
      render json: { containers: RepositoryEntity.represent(repositories).as_json }
    end

    def associate
      if repository
        render json: RepositoryEntity.represent(repository).as_json
      else
        render json: { error: 'Repository not found.' }, status: :not_found
      end
    end

    private

    def search_query
      @_search_query ||= ActionController::Base.helpers.sanitize(query_params[:searchQuery].to_s)
    end

    def query_params
      params.permit(:id, :searchQuery, :page, :limit)
    end

    def available_repositories
      @_available_repositories ||= Project.with_jira_installation(current_jira_installation.id)
    end

    def repository
      @_repository ||= available_repositories.find_by_id(query_params[:id])
    end
  end
end
