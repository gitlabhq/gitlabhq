class PipelinesFinder
  attr_reader :project, :pipelines, :params

  def initialize(project, params = {})
    @project = project
    @pipelines = project.pipelines
    @params = params
  end

  def execute
    items = pipelines
    items = by_scope(items)
    items = by_status(items)
    items = by_ref(items)
    items = by_user(items)
    items = by_duration(items)
    items = by_yaml_error(items)
    order_and_sort(items)
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

  def by_scope(items)
    case params[:scope]
    when 'running'
      items.running
    when 'pending'
      items.pending
    when 'finished'
      items.finished
    when 'branches'
      from_ids(ids_for_ref(branches))
    when 'tags'
      from_ids(ids_for_ref(tags))
    else
      items
    end
  end

  def by_status(items)
    case params[:status]
    when 'running'
      items.running
    when 'pending'
      items.pending
    when 'success'
      items.success
    when 'failed'
      items.failed
    when 'canceled'
      items.canceled
    when 'skipped'
      items.skipped
    else
      items
    end
  end

  def by_ref(items)
    if params[:ref].present?
      items.where(ref: params[:ref])
    else
      items
    end
  end

  def by_user(items)
    if params[:user_id].present?
      items.where(user_id: params[:user_id])
    else
      items
    end
  end
  
  def by_duration(items)
    if params[:duration].present?
      items.where("duration > ?", params[:duration])
    else
      items
    end
  end

  def by_yaml_error(items)
    if params[:yaml_error].present? && params[:yaml_error]
      items.where("yaml_errors IS NOT NULL")
    else
      items
    end
  end

  def order_and_sort(items)
    if params[:order_by].present? && params[:sort].present?
      items.order("#{params[:order_by]} #{params[:sort]}")
    else
      items.order(id: :desc)
    end
  end
end
