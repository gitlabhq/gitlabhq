module Search
  class GlobalService
    include Gitlab::CurrentSettings

    attr_accessor :current_user, :params

    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      group = Group.find_by(id: params[:group_id]) if params[:group_id].present?
      projects = ProjectsFinder.new.execute(current_user)

      if group
        projects = projects.inside_path(group.full_path)
      end

      if current_application_settings.elasticsearch_search?
        projects = current_user ? current_user.authorized_projects : Project.none
        projects = projects.inside_path(group.id) if group

        Gitlab::Elastic::SearchResults.new(
          current_user,
          params[:search],
          projects.pluck(:id),
          !group
        )
      else
        Gitlab::SearchResults.new(current_user, projects, params[:search])
      end
    end
  end
end
