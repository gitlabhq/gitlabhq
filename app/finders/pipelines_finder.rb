class PipelinesFinder
  attr_reader :project, :pipelines, :params

  ALLOWED_INDEXED_COLUMNS = %w[id status ref user_id].freeze

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
    items = by_sha(items)
    items = by_name(items)
    items = by_username(items)
    items = by_yaml_errors(items)
    sort_items(items)
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
    return items unless HasStatus::AVAILABLE_STATUSES.include?(params[:status])

    items.where(status: params[:status])
  end

  def by_ref(items)
    if params[:ref].present?
      items.where(ref: params[:ref])
    else
      items
    end
  end

  def by_sha(items)
    if params[:sha].present?
      items.where(sha: params[:sha])
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

  def sort_items(items)
    order_by = if ALLOWED_INDEXED_COLUMNS.include?(params[:order_by])
                 params[:order_by]
               else
                 :id
               end

    sort = if params[:sort] =~ /\A(ASC|DESC)\z/i
             params[:sort]
           else
             :desc
           end

    items.order(order_by => sort)
  end
end
