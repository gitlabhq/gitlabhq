class Explore::ProjectsController < Explore::ApplicationController
  def index
    @projects = ProjectsFinder.new.execute(current_user)
    @tags = @projects.tags_on(:tags)
    @projects = @projects.tagged_with(params[:tag]) if params[:tag].present?
    @projects = @projects.where(visibility_level: params[:visibility_level]) if params[:visibility_level].present?
    @projects = @projects.non_archived
    @projects = @projects.search(params[:search]) if params[:search].present?
    @projects = @projects.sort(@sort = params[:sort])
    @projects = @projects.includes(:namespace).page(params[:page]).per(PER_PAGE)
  end

  def trending
    @trending_projects = TrendingProjectsFinder.new.execute(current_user)
    @trending_projects = @trending_projects.non_archived
    @trending_projects = @trending_projects.page(params[:page]).per(PER_PAGE)
  end

  def starred
    @starred_projects = ProjectsFinder.new.execute(current_user)
    @starred_projects = @starred_projects.reorder('star_count DESC')
    @starred_projects = @starred_projects.page(params[:page]).per(PER_PAGE)
  end
end
