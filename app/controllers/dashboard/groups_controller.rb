class Dashboard::GroupsController < Dashboard::ApplicationController
  def index
    @groups = if params[:parent_id]
                parent = Group.find(params[:parent_id])

                if parent.users_with_parents.find_by(id: current_user)
                  Group.where(id: parent.children)
                else
                  Group.none
                end
              else
                Group.joins(:group_members).merge(current_user.group_members)
              end

    @groups = @groups.search(params[:filter_groups]) if params[:filter_groups].present?
    @groups = @groups.includes(:route)
    @groups = @groups.sort(@sort = params[:sort])
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
