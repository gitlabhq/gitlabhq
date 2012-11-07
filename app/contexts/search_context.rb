class SearchContext
  attr_accessor :project_ids, :params

  def initialize(project_ids, params)
    @project_ids, @params = project_ids, params.dup
  end

  def execute
    query = params[:search]

    return result unless query.present?

    result[:projects] = Project.where(id: project_ids).search(query).limit(10)
    result[:merge_requests] = MergeRequest.where(project_id: project_ids).search(query).limit(10)
    result[:issues] = Issue.where(project_id: project_ids).search(query).limit(10)
    result
  end

  def result
    @result ||= {
      projects: [],
      merge_requests: [],
      issues: []
    }
  end
end

