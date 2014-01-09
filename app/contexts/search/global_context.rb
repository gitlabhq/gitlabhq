module Search
  class GlobalContext
    attr_accessor :current_user, :params

    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      query = params[:search]
      query = Shellwords.shellescape(query) if query.present?
      return result unless query.present?


      projects = current_user.authorized_projects

      if params[:group_id].present?
        group = Group.find_by_id(params[:group_id])
        projects = projects.where(namespace_id: group.id) if group
      end

      project_ids = projects.pluck(:id)

      visibility_levels = if current_user
                            [Gitlab::VisibilityLevel::INTERNAL, Gitlab::VisibilityLevel::PUBLIC]
                          else
                            [Gitlab::VisibilityLevel::PUBLIC]
                          end
      result[:projects] = Project.where("projects.id in (?) OR projects.visibility_level in (?)", project_ids, visibility_levels).search(query).limit(20)
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
