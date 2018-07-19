# frozen_string_literal: true

module Search
  class ProjectService
    attr_accessor :project, :current_user, :params

    def initialize(project, user, params)
      @project, @current_user, @params = project, user, params.dup
    end

    def execute
      if Gitlab::CurrentSettings.elasticsearch_search?
        Gitlab::Elastic::ProjectSearchResults.new(current_user,
                                                  params[:search],
                                                  project.id,
                                                  params[:repository_ref])
      else
        Gitlab::ProjectSearchResults.new(current_user,
                                         project,
                                         params[:search],
                                         params[:repository_ref])
      end
    end

    def scope
      @scope ||= %w[notes issues merge_requests milestones wiki_blobs commits].delete(params[:scope]) { 'blobs' }
    end
  end
end
