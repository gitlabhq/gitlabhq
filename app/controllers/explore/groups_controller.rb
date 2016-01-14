class Explore::GroupsController < Explore::ApplicationController
  def index
    @groups = Group.order_id_desc
    @groups = @groups.search(params[:search]) if params[:search].present?
    @groups = @groups.sort(@sort = params[:sort])
    @groups = @groups.page(params[:page]).per(PER_PAGE)
  end
end
