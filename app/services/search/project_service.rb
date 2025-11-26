# frozen_string_literal: true

module Search
  class ProjectService
    include Search::Filter
    include Gitlab::Utils::StrongMemoize

    LEGACY_ALLOWED_SCOPES = %w[blobs issues merge_requests wiki_blobs commits notes milestones users].freeze

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
        filters: filters
      )
    end

    def allowed_scopes
      return legacy_allowed_scopes unless Feature.enabled?(:search_scope_registry, :instance)

      Search::Scopes.available_for_context(
        context: :project,
        container: searched_container,
        requested_search_type: params[:search_type]
      )
    end

    def scope
      search_navigation = Search::Navigation.new(user: current_user, project: project)
      scope = params[:scope]
      return scope if allowed_scopes.include?(scope) && search_navigation.tab_enabled_for_project?(scope.to_sym)

      if ::Gitlab::CurrentSettings.custom_default_search_scope_set? &&
          allowed_scopes.include?(::Gitlab::CurrentSettings.default_search_scope) &&
          search_navigation.tab_enabled_for_project?(::Gitlab::CurrentSettings.default_search_scope.to_sym)
        return ::Gitlab::CurrentSettings.default_search_scope
      end

      allowed_scopes.find do |s|
        search_navigation.tab_enabled_for_project?(s.to_sym)
      end
    end
    strong_memoize_attr :scope

    private

    def legacy_allowed_scopes
      LEGACY_ALLOWED_SCOPES
    end

    def searched_container
      project
    end
  end
end

Search::ProjectService.prepend_mod_with('Search::ProjectService')
