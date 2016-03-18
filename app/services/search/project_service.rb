module Search
  class ProjectService
    attr_accessor :project, :current_user, :params

    def initialize(project, user, params)
      @project, @current_user, @params = project, user, params.dup
    end

    def execute
      if Gitlab.config.elasticsearch.enabled
        Gitlab::Elastic::ProjectSearchResults.new(current_user,
                                                  project.id,
                                                  params[:search],
                                                  params[:repository_ref])
      else
        Gitlab::ProjectSearchResults.new(current_user,
                                         project,
                                         params[:search],
                                         params[:repository_ref])
      end
    end
  end
end
