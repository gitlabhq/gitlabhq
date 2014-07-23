class Public::ExploreController < ApplicationController
  skip_before_filter :authenticate_user!,
    :reject_blocked,
    :add_abilities

  layout "public"

  def index
    @trending_projects = TrendingProjectsFinder.new.execute(current_user)
    @trending_projects = @trending_projects.page(params[:page]).per(10)
  end
end
