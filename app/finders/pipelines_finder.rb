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
    items = by_name(items)
    items = by_username(items)
    items = by_yaml_errors(items)
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

  def by_name(items)
    if params[:name].present?
      items.joins(:user).where(users: { name: params[:name] })
    else
      items
    end
  end

  def by_username(items)
    if params[:username].present?
      items.joins(:user).where(users: { username: params[:username] })
    else
      items
    end
  end

  def by_yaml_errors(items)
    case Gitlab::Utils.to_boolean(params[:yaml_errors])
    when true
      items.where("yaml_errors IS NOT NULL")
    when false
      items.where("yaml_errors IS NULL")
    else
      items
    end
  end

  def order_and_sort(items)
    order_by = if params[:order_by].present? && items.column_names.include?(params[:order_by])
                 params[:order_by]
               else
                 :id
               end
    sort = if params[:sort].present? && params[:sort] =~ /\A(ASC|DESC)\z/i
             params[:sort]
           else
             :desc
           end
    items.reorder(order_by => sort)
  end
end
