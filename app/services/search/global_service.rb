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
      projects = projects.in_namespace(group.id) if group

      if current_application_settings.elasticsearch_search?
        Gitlab::Elastic::SearchResults.new(current_user, projects.pluck(:id), params[:search])
      else
        Gitlab::SearchResults.new(current_user, projects, params[:search])
      end
    end
  end
end
