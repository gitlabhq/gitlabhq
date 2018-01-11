module GroupTree
  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def render_group_tree(groups)
    @groups = if params[:filter].present?
                Gitlab::GroupHierarchy.new(groups.search(params[:filter]))
                  .base_and_ancestors
              else
                # Only show root groups if no parent-id is given
                groups.where(parent_id: params[:parent_id])
              end

    @groups = @groups.with_selects_for_list(archived: params[:archived])
                .sort(@sort = params[:sort])
                .page(params[:page])

    respond_to do |format|
      format.html
      format.json do
        serializer = GroupChildSerializer.new(current_user: current_user)
                       .with_pagination(request, response)
        serializer.expand_hierarchy if params[:filter].present?
        render json: serializer.represent(@groups)
      end
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables
  end
end
