module Search
  class GlobalService
    attr_accessor :current_user, :params

    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      group = Group.find_by(id: params[:group_id]) if params[:group_id].present?
      projects = ProjectsFinder.new.execute(current_user)
      projects = projects.where(namespace_id: group.id) if group
      project_ids = projects.pluck(:id)

      Gitlab::SearchResults.new(project_ids, params[:search])
    end
  end
end
