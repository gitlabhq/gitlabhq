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
    else
      pipelines
    end
  end

  private

  def ids_for_ref(pipelines, refs)
    pipelines.where(ref: refs).group(:ref).select('max(id)')
  end

  def from_ids(pipelines, ids)
    pipelines.unscoped.where(id: ids)
  end

  def branches
    project.repository.branch_names
  end

  def tags
    project.repository.tag_names
  end
end
