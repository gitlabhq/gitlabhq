# frozen_string_literal: true

module Search
  class GlobalService
    include Search::Filter
    include Gitlab::Utils::StrongMemoize

    DEFAULT_SCOPE = 'projects'
    LEGACY_ALLOWED_SCOPES = %w[projects issues merge_requests milestones users].freeze

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

    # rubocop: disable CodeReuse/ActiveRecord
    def projects
      @projects ||= ::ProjectsFinder.new(current_user: current_user).execute.preload(:topics, :project_topics, :route)
    end

    def allowed_scopes
      return legacy_allowed_scopes unless Feature.enabled?(:search_scope_registry, :instance)

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

    def legacy_allowed_scopes
      LEGACY_ALLOWED_SCOPES
    end

    # Global search doesn't have a container
    def searched_container; end
  end
end

Search::GlobalService.prepend_mod_with('Search::GlobalService')
