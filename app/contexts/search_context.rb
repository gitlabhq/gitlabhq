class SearchContext
  attr_accessor :project_ids, :current_user, :params

  def initialize(project_ids, user, params)
    @project_ids, @current_user, @params = project_ids, user, params.dup
  end

  def execute
    query = params[:search]
    query = Shellwords.shellescape(query) if query.present?

    return result unless query.present?
    visibility_levels = @current_user ? [ Gitlab::VisibilityLevel::INTERNAL, Gitlab::VisibilityLevel::PUBLIC ] : [ Gitlab::VisibilityLevel::PUBLIC ]
    result[:projects] = Project.where("projects.id in (?) OR projects.visibility_level in (?)", project_ids, visibility_levels).search(query).limit(20)

    # Search inside single project
    single_project_search(Project.where(id: project_ids), query)
    result
  end

  def single_project_search(projects, query)
    project = projects.first if projects.length == 1

    if params[:search_code].present?
      result[:blobs] = project.repository.search_files(query, params[:repository_ref]) unless project.empty_repo?
    else
      result[:merge_requests] = MergeRequest.in_projects(project_ids).search(query).order('updated_at DESC').limit(20)
      result[:issues] = Issue.where(project_id: project_ids).search(query).order('updated_at DESC').limit(20)
      result[:wiki_pages] = []
    end
  end

  def result
    @result ||= {
      projects: [],
      merge_requests: [],
      issues: [],
      wiki_pages: [],
      blobs: []
    }
  end
end
