module Search
  class GlobalService
    attr_accessor :current_user, :params

    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      query = params[:search]
      query = Shellwords.shellescape(query) if query.present?
      return result unless query.present?

      group = Group.find_by(id: params[:group_id]) if params[:group_id].present?
      projects = ProjectsFinder.new.execute(current_user)
      projects = projects.where(namespace_id: group.id) if group
      project_ids = projects.pluck(:id)

      result[:projects] = projects.search(query).limit(20)
      result[:merge_requests] = MergeRequest.in_projects(project_ids).search(query).order('updated_at DESC').limit(20)
      result[:issues] = Issue.where(project_id: project_ids).search(query).order('updated_at DESC').limit(20)
      result[:total_results] = %w(projects issues merge_requests).sum { |items| result[items.to_sym].size }
      result
    end

    def result
      @result ||= {
        projects: [],
        merge_requests: [],
        issues: [],
        notes: [],
        total_results: 0,
      }
    end
  end
end
