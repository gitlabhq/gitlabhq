module Search
  class ProjectService
    attr_accessor :project, :current_user, :params

    def initialize(project, user, params)
      @project, @current_user, @params = project, user, params.dup
    end

    def execute
<<<<<<< HEAD
      if Gitlab.config.elasticsearch.enabled
        Gitlab::Elastic::ProjectSearchResults.new(project.id,
                                         params[:search],
                                         params[:repository_ref])
      else
        Gitlab::ProjectSearchResults.new(project.id,
                                         params[:search],
                                         params[:repository_ref])
      end
=======
      Gitlab::ProjectSearchResults.new(project,
                                       params[:search],
                                       params[:repository_ref])
>>>>>>> ce/master
    end
  end
end
