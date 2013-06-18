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

    # Search inside singe project
    project = projects.first if projects.length == 1

    if params[:search_code].present?
      result[:blobs] = project.repository.search_files(query, params[:repository_ref]) unless project.empty_repo?
    else
      result[:merge_requests] = MergeRequest.where(project_id: project_ids).search(query).limit(10)
      result[:issues] = Issue.where(project_id: project_ids).search(query).limit(10)
      projects.each do |p|
        wiki = GollumWiki.new(p)
#        Rails.logger.info wiki
        t=wiki.search_i(query)
#        Rails.logger.info t[0][:wiki].path
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
      blobs: []
    }
  end
end
