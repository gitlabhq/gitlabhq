class Dashboard::GroupsController < Dashboard::ApplicationController
  def index
    @groups =
      if params[:parent_id] && Group.supports_nested_groups?
        parent = Group.find_by(id: params[:parent_id])

        if can?(current_user, :read_group, parent)
          GroupsFinder.new(current_user, parent: parent).execute
        else
          Group.none
        end
      else
        current_user.groups
      end

    @groups = @groups.search(params[:filter_groups]) if params[:filter_groups].present?
    @groups = @groups.includes(:route)
    @groups = @groups.sort_by_attr(@sort = params[:sort])
    @groups = @groups.page(params[:page])

    respond_to do |format|
      format.html
      format.json do
        render json: GroupSerializer
          .new(current_user: @current_user)
          .with_pagination(request, response)
          .represent(@groups)
      end
    end
  end
end
