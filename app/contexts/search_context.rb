class SearchContext < BaseContext
  attr_accessor :current_user, :params

  def initialize(user, params)
    @current_user, @params = user, params.dup
  end

  def execute
    project_id = params[:project_id]
    group_id = params[:group_id]

    projects = current_user.authorized_projects

    if group_id.present?
      @group = Group.find(group_id)
      projects = @group.projects.where(id: projects)
    elsif project_id.present?
      @project = Project.find(project_id)
      projects = projects.where(id: @project)
    end

    query = params[:search]

    return result unless query.present?

    result[:projects] = projects.search(query).limit(10)

    # Search inside singe project
    project = projects.first if projects.length == 1

    if params[:search_code].present?
      result[:blobs] = project.repository.search_files(query, params[:repository_ref]) unless project.empty_repo?
    else
      result[:merge_requests] = MergeRequest.where(project_id: projects).search(query).limit(10)
      result[:issues] = Issue.where(project_id: projects).search(query).limit(10)
      result[:wiki_pages] = []
    end

    result
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
