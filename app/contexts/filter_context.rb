class FilterContext
  attr_accessor :items, :params

  def initialize(items, params)
    @items = items
    @params = params
  end

  def execute
    apply_filter(items)
  end

  def apply_filter items
    if params[:project_id]
      items = items.where(project_id: params[:project_id])
    end

    if params[:search].present?
      items = items.search(params[:search])
    end

    case params[:status]
    when 'closed'
      items.closed
    when 'all'
      items
    else
      items.opened
    end
  end
end
