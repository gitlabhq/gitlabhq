module Search
  class GlobalService
    attr_accessor :current_user, :params

    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      group = Group.find_by(id: params[:group_id]) if params[:group_id].present?
      projects = ProjectsFinder.new.execute(current_user)
      projects = projects.in_namespace(group.id) if group

<<<<<<< HEAD
      if Gitlab.config.elasticsearch.enabled
        Gitlab::Elastic::SearchResults.new(project_ids, params[:search])
      else
        Gitlab::SearchResults.new(project_ids, params[:search])
      end
=======
      Gitlab::SearchResults.new(projects, params[:search])
>>>>>>> ce/master
    end
  end
end
