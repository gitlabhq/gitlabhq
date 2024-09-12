# frozen_string_literal: true

module Search
  class GlobalService
    include Search::Filter
    include Gitlab::Utils::StrongMemoize

    DEFAULT_SCOPE = 'projects'
    ALLOWED_SCOPES = %w[projects issues merge_requests milestones users].freeze

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
        filters: filters)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def projects
      @projects ||= ::ProjectsFinder.new(current_user: current_user).execute.preload(:topics, :project_topics, :route)
    end

    def allowed_scopes
      ALLOWED_SCOPES
    end

    def scope
      strong_memoize(:scope) do
        allowed_scopes.include?(params[:scope]) ? params[:scope] : DEFAULT_SCOPE
      end
    end
  end
end

Search::GlobalService.prepend_mod_with('Search::GlobalService')
