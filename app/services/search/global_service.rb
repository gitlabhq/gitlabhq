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

      authorized_projects_ids = []
      authorized_projects_ids += current_user.authorized_projects.pluck(:id) if current_user
      authorized_projects_ids += Project.public_or_internal_only(current_user).pluck(:id)

      group = Group.find_by(id: params[:group_id]) if params[:group_id].present?
      projects = Project.where(id: authorized_projects_ids)
      projects = projects.where(namespace_id: group.id) if group
      projects = projects.search(query)
      project_ids = projects.pluck(:id)

      result[:projects] = projects.limit(20)
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
        total_results: 0,
      }
    end
  end
end
