class PipelinesFinder
  attr_reader :project, :pipelines

  def initialize(project)
    @project = project
    @pipelines = project.pipelines
  end

  def execute(scope: nil)
    scoped_pipelines =
      case scope
      when 'running'
        pipelines.running_or_pending
      when 'branches'
        from_ids(ids_for_ref(branches))
      when 'tags'
        from_ids(ids_for_ref(tags))
      else
        pipelines
      end

    scoped_pipelines.order(id: :desc)
  end

  private

  def ids_for_ref(refs)
    pipelines.where(ref: refs).group(:ref).select('max(id)')
  end

  def from_ids(ids)
    pipelines.unscoped.where(id: ids)
  end

  def branches
    project.repository.branch_names
  end

  def tags
    project.repository.tag_names
  end
end
