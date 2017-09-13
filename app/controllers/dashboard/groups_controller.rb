class Dashboard::GroupsController < Dashboard::ApplicationController
  def index
    @groups = GroupsFinder.new(current_user, all_available: false).execute
    # Only show root groups if no parent-id is given
    @groups = @groups.where(parent_id: params[:parent_id])
    @groups = @groups.search(params[:filter]) if params[:filter].present?
    @groups = @groups.includes(:route)
    @groups = @groups.sort(@sort = params[:sort])
    @groups = @groups.page(params[:page])

    respond_to do |format|
      format.html
      format.json do
        serializer = GroupChildSerializer.new(current_user: current_user)
                       .with_pagination(request, response)
        render json: serializer.represent(@groups)
      end
    end
  end
end
