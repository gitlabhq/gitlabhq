module Search
  class GlobalService
    attr_accessor :current_user, :params

    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      group = Group.find_by(id: params[:group_id]) if params[:group_id].present?
      projects = ProjectsFinder.new(current_user: current_user).execute

      if group
        projects = projects.inside_path(group.full_path)
      end

      Gitlab::SearchResults.new(current_user, projects, params[:search])
    end

    def scope
      @scope ||= begin
        allowed_scopes = %w[issues merge_requests milestones]

        allowed_scopes.delete(params[:scope]) { 'projects' }
      end
    end
  end
end
