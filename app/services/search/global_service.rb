# frozen_string_literal: true

module Search
  class GlobalService
    include Search::Filter
    include Gitlab::Utils::StrongMemoize

    DEFAULT_SCOPE = 'projects'

    attr_accessor :current_user, :params

    def initialize(user, params)
      @current_user = user
      @params = params.dup
    end

    def execute
      Gitlab::SearchResults.new(current_user,
        params[:search],
        projects,
        order_by: params[:order_by],
        sort: params[:sort],
        filters: filters
      )
    end

    def projects
      @projects ||= if Feature.enabled?(:search_project_list_lookup, current_user)
                      ::ProjectsFinder.new(current_user: current_user).execute.with_route.include_topics.without_order
                    else
                      ::ProjectsFinder.new(current_user: current_user).execute.preload(:topics, :project_topics, :route) # rubocop:disable CodeReuse/ActiveRecord -- existing code
                    end
    end

    def allowed_scopes
      Search::Scopes.available_for_context(
        context: :global,
        container: searched_container,
        requested_search_type: params[:search_type]
      )
    end

    def scope
      allowed_scopes.include?(params[:scope]) ? params[:scope] : default_search_scope
    end
    strong_memoize_attr :scope

    private

    def default_search_scope
      if ::Gitlab::CurrentSettings.custom_default_search_scope_set? &&
          allowed_scopes.include?(::Gitlab::CurrentSettings.default_search_scope)
        return ::Gitlab::CurrentSettings.default_search_scope
      end

      DEFAULT_SCOPE
    end

    # Global search doesn't have a container
    def searched_container; end
  end
end

Search::GlobalService.prepend_mod_with('Search::GlobalService')
