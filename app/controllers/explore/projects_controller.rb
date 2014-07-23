class Explore::ProjectsController < ApplicationController
  skip_before_filter :authenticate_user!,
    :reject_blocked,
    :add_abilities

  layout 'explore'

  def index
    @projects = ProjectsFinder.new.execute(current_user)
    @projects = @projects.search(params[:search]) if params[:search].present?
    @projects = @projects.sort(@sort = params[:sort])
    @projects = @projects.includes(:namespace).page(params[:page]).per(20)
  end

  def trending
    @trending_projects = TrendingProjectsFinder.new.execute(current_user)
    @trending_projects = @trending_projects.page(params[:page]).per(10)
  end
end
