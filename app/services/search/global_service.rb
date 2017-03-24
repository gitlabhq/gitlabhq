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
        unless group
          projects = current_user ? current_user.authorized_projects : Project.none
        end

        Gitlab::Elastic::SearchResults.new(
          current_user,
          params[:search],
          projects.pluck(:id),
          !group # Ignore public projects outside of the group if provided
        )
      else
        Gitlab::SearchResults.new(current_user, projects, params[:search])
      end
    end
  end
end
