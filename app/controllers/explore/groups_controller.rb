class Explore::GroupsController < ApplicationController
  skip_before_filter :authenticate_user!,
                     :reject_blocked, :set_current_user_for_observers,
                     :add_abilities

  layout "explore"

  def index
    @groups = GroupsFinder.new.execute(current_user)
    @groups = @groups.search(params[:search]) if params[:search].present?
    @groups = @groups.sort(@sort = params[:sort])
    @groups = @groups.page(params[:page]).per(20)
  end
end
