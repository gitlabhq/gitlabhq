module Search
  class GlobalService
    attr_accessor :current_user, :params
    attr_reader :default_project_filter

    def initialize(user, params)
      @current_user, @params = user, params.dup
      @default_project_filter = true
    end

    def execute
      Gitlab::SearchResults.new(current_user, projects, params[:search],
                                default_project_filter: default_project_filter)
    end

    def projects
      @projects ||= ProjectsFinder.new(current_user: current_user).execute
    end

    def scope
      @scope ||= begin
        allowed_scopes = %w[issues merge_requests milestones]

        allowed_scopes.delete(params[:scope]) { 'projects' }
      end
    end
  end
end
