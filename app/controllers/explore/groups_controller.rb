class Explore::GroupsController < Explore::ApplicationController
  def index
    @groups = GroupsFinder.new.execute(current_user)
    @groups = @groups.search(params[:search]) if params[:search].present?
    @groups = @groups.sort2(@sort = params[:sort])
    @groups = @groups.page(params[:page])
  end
end
