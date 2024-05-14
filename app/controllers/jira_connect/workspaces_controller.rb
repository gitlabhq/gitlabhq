# frozen_string_literal: true

module JiraConnect
  class WorkspacesController < JiraConnect::ApplicationController
    feature_category :integrations

    def search
      namespaces = available_namespaces.by_name(search_query)
      render json: { workspaces: JiraConnect::WorkspaceEntity.represent(namespaces).as_json }
    end

    private

    def search_query
      @_search_query ||= ActionController::Base.helpers.sanitize(params[:searchQuery].to_s)
    end

    def available_namespaces
      @_available_namespaces ||= Namespace.without_project_namespaces
        .with_jira_installation(current_jira_installation.id)
    end
  end
end
