# frozen_string_literal: true

module Search
  class ProjectService
    include Search::Filter
    include Gitlab::Utils::StrongMemoize

    attr_accessor :project, :current_user, :params

    def initialize(user, project, params)
      @current_user = user
      @project = project
      @params = params.dup
    end

    def execute
      Gitlab::ProjectSearchResults.new(current_user,
        params[:search],
        project: project,
        repository_ref: params[:repository_ref],
        order_by: params[:order_by],
        sort: params[:sort],
        filters: filters,
        organization_id: params[:organization_id]
      )
    end

    def allowed_scopes
      Search::Scopes.available_for_context(
        context: :project,
        container: searched_container,
        requested_search_type: params[:search_type]
      )
    end

    def scope
      scope = params[:scope]
      return scope if allowed_scopes.include?(scope) && scope_allowed_for_project?(scope)

      if ::Gitlab::CurrentSettings.custom_default_search_scope_set? &&
          allowed_scopes.include?(::Gitlab::CurrentSettings.default_search_scope) &&
          scope_allowed_for_project?(::Gitlab::CurrentSettings.default_search_scope)
        return ::Gitlab::CurrentSettings.default_search_scope
      end

      allowed_scopes.find { |s| scope_allowed_for_project?(s) }
    end
    strong_memoize_attr :scope

    private

    def scope_allowed_for_project?(scope)
      Search::Scopes.scope_allowed_for_project?(scope, current_user, project)
    end

    def searched_container
      project
    end
  end
end

Search::ProjectService.prepend_mod_with('Search::ProjectService')
