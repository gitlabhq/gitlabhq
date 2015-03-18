class Dashboard::GroupsController < ApplicationController
  def index
    @group_members = current_user.group_members.page(params[:page]).per(PER_PAGE)
  end
end
