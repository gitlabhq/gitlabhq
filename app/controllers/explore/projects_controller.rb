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
    @projects = TrendingProjectsFinder.new.execute(current_user)
    @projects = @projects.non_archived
    @projects = @projects.page(params[:page]).per(PER_PAGE)
  end

  def starred
    @projects = ProjectsFinder.new.execute(current_user)
    @projects = @projects.reorder('star_count DESC')
    @projects = @projects.page(params[:page]).per(PER_PAGE)
  end
end
