class SearchContext
  attr_accessor :project_ids, :params

  def initialize(project_ids, params)
    @project_ids, @params = project_ids, params.dup
  end

  def execute
    query = params[:search]

    return result unless query.present?

    projects = Project.where(id: project_ids)
    result[:projects] = projects.search(query).limit(10)

    # Search inside single project
    project = projects.first if projects.length == 1
    case params[:search_code].to_i
      when 1 #.present?
        result[:blobs] = project.repository.search_files(query, params[:repository_ref]) unless project.empty_repo?
      when 3
        result[:wiki_pages_blob]= GollumWiki.new(project).search_files(query)
      else
        result[:merge_requests] = MergeRequest.where(project_id: project_ids).search(query).limit(10)
        result[:issues] = Issue.where(project_id: project_ids).search(query).limit(10)
        projects.each do |p|
          wiki = GollumWiki.new(p)
          t=wiki.search_i(query)
          result[:wiki_pages] += t 
        end
        #result[:wiki_pages] = [] #GollumWiki.where(project_id: project_ids).wiki.search(query)
    end
    result
  end

  def result
    @result ||= {
      projects: [],
      merge_requests: [],
      issues: [],
      wiki_pages: [],
      wiki_pages_blob: [],
      blobs: []
    }
  end
end
