class PipelinesFinder
  attr_reader :project

  def initialize(project)
    @project = project
  end

  def execute(pipelines, scope)
    case scope
    when 'running'
      pipelines.running_or_pending
    when 'branches'
      from_ids(pipelines, ids_for_ref(pipelines, branches))
    when 'tags'
      from_ids(pipelines, ids_for_ref(pipelines, tags))
    when 'merge_requests'
      from_ids(Ci::Pipeline, ids_for_merge_requests(project))
    else
      pipelines
    end
  end

  private

  def ids_for_ref(pipelines, refs)
    pipelines.where(ref: refs).group(:ref).select('max(id)')
  end

  def ids_for_merge_requests(project)
    Ci::Pipeline.
      joins('JOIN merge_requests ON merge_requests.source_project_id=ci_commits.gl_project_id AND merge_requests.source_branch=ci_commits.ref').
      where('merge_requests.target_project_id=?', project.id)
  end

  def from_ids(pipelines, ids)
    pipelines.unscoped.where(id: ids)
  end

  def branches
    project.repository.branches.map(&:name)
  end

  def tags
    project.repository.tags.map(&:name)
  end
end
