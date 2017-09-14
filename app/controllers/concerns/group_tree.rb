module GroupTree
  def render_group_tree(groups)
    if params[:filter].present?
      @groups = Gitlab::GroupHierarchy.new(groups).all_groups
      @groups = @groups.search(params[:filter])
    else
      # Only show root groups if no parent-id is given
      @groups = groups.where(parent_id: params[:parent_id])
    end
    @groups = @groups.includes(:route)
    @groups = @groups.sort(@sort = params[:sort])
    @groups = @groups.page(params[:page])

    respond_to do |format|
      format.html
      format.json do
        serializer = GroupChildSerializer.new(current_user: current_user)
                       .with_pagination(request, response)
        serializer.expand_hierarchy if params[:filter].present?
        render json: serializer.represent(@groups)
      end
    end
  end
end
