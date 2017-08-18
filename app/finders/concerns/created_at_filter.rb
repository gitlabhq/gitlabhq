module CreatedAtFilter
  def by_created_at(items)
    items = items.created_before(params[:created_before]) if params[:created_before].present?
    items = items.created_after(params[:created_after]) if params[:created_after].present?

    items
  end
end
