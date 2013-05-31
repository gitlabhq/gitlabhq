class SearchContext
  attr_accessor :project_ids, :params

  def initialize(project_ids, params)
    @project_ids, @params = project_ids, params.dup
  end

  def execute
    query = params[:search]


    projects = Project.where(id: project_ids)
    result[:projects] = projects.search(query).limit(10)

    # Search inside singe project
    result[:project] = project = projects.first if projects.length == 1

    return result unless query.present?

    if params[:search_code] == "true"
      if project.nil?
        result[:blobs] = search_projects(Project.all.delete_if { |proj| proj.empty_repo? }, query, nil)
      else
        result[:blobs] = search_projects(project, query, params[:repository_ref]) unless project.empty_repo?
      end
    else
      result[:merge_requests] = MergeRequest.where(project_id: project_ids).search(query).limit(10)
      result[:issues] = Issue.where(project_id: project_ids).search(query).limit(10)
      result[:wiki_pages] = []
    end
    result
  end

  def search_projects(projects, query, ref)
    # trick to make sure that projects is array
    projects = [projects].flatten

    search_results = projects.map do |current_project|
      repo = current_project.repository
      blobs = repo.search_files(query, ref)
      blobs.map! { |blob| {blob: blob, project: current_project} }
    end

    search_results.flatten
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
