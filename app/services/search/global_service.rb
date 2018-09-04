# frozen_string_literal: true

module Search
  class GlobalService
    attr_accessor :current_user, :params
    attr_reader :default_project_filter

    def initialize(user, params)
      @current_user, @params = user, params.dup
      @default_project_filter = true
    end

    def execute
      if Gitlab::CurrentSettings.elasticsearch_search?
        Gitlab::Elastic::SearchResults.new(current_user, params[:search], elastic_projects, elastic_global)
      else
        Gitlab::SearchResults.new(current_user, projects, params[:search],
                                  default_project_filter: default_project_filter)
      end
    end

    def projects
      @projects ||= ProjectsFinder.new(current_user: current_user).execute
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def elastic_projects
      @elastic_projects ||=
        if current_user&.full_private_access?
          :any
        elsif current_user
          current_user.authorized_projects.pluck(:id)
        else
          []
        end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def elastic_global
      true
    end

    def scope
      @scope ||= begin
        allowed_scopes = %w[issues merge_requests milestones]
        allowed_scopes += %w[wiki_blobs blobs commits] if Gitlab::CurrentSettings.elasticsearch_search?

        allowed_scopes.delete(params[:scope]) { 'projects' }
      end
    end
  end
end
