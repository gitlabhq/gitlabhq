# frozen_string_literal: true

module Search
  class ProjectService
    attr_accessor :project, :current_user, :params

    def initialize(project, user, params)
      @project, @current_user, @params = project, user, params.dup
    end

    def execute
      Gitlab::ProjectSearchResults.new(current_user,
                                       project,
                                       params[:search],
                                       params[:repository_ref])
    end

    def scope
      @scope ||= begin
        allowed_scopes = %w[notes issues merge_requests milestones wiki_blobs commits]
        allowed_scopes << 'users' if Feature.enabled?(:users_search, default_enabled: true)

        allowed_scopes.delete(params[:scope]) { 'blobs' }
      end
    end
  end
end
