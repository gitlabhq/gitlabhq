# frozen_string_literal: true

module Search
  class GlobalService
    include Gitlab::Utils::StrongMemoize

    attr_accessor :current_user, :params

    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      Gitlab::SearchResults.new(current_user,
                                params[:search],
                                projects,
                                filters: { state: params[:state], confidential: params[:confidential] })
    end

    def projects
      @projects ||= ProjectsFinder.new(params: { non_archived: true }, current_user: current_user).execute
    end

    def allowed_scopes
      strong_memoize(:allowed_scopes) do
        allowed_scopes = %w[issues merge_requests milestones]
        allowed_scopes << 'users' if Feature.enabled?(:users_search, default_enabled: true)
      end
    end

    def scope
      strong_memoize(:scope) do
        allowed_scopes.include?(params[:scope]) ? params[:scope] : 'projects'
      end
    end
  end
end

Search::GlobalService.prepend_if_ee('EE::Search::GlobalService')
