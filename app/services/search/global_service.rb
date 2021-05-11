# frozen_string_literal: true

module Search
  class GlobalService
    include Gitlab::Utils::StrongMemoize

    ALLOWED_SCOPES = %w(issues merge_requests milestones users).freeze

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
                                filters: { state: params[:state], confidential: params[:confidential] })
    end

    def projects
      @projects ||= ProjectsFinder.new(params: { non_archived: true }, current_user: current_user).execute
    end

    def allowed_scopes
      ALLOWED_SCOPES
    end

    def scope
      strong_memoize(:scope) do
        allowed_scopes.include?(params[:scope]) ? params[:scope] : 'projects'
      end
    end
  end
end

Search::GlobalService.prepend_mod_with('Search::GlobalService')
