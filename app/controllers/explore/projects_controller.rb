class Explore::ProjectsController < Explore::ApplicationController
  include ProjectsListing

  # The explore page doesn't use the new filters & sorts.
  skip_before_action :load_filter_and_sort
  # But it needs to show the user's own projects & her starred projects
  before_action :load_user_projects, :load_starred_projects, if: :current_user

  def index
    @projects = ProjectsFinder.new.execute(current_user).non_archived.includes(:namespace)
    @tags = @projects.tags_on(:tags)
    @projects = @projects.tagged_with(params[:tag]) if params[:tag].present?
    @projects = @projects.where(visibility_level: params[:visibility_level]) if params[:visibility_level].present?
    @projects = @projects.search(params[:search]) if params[:search].present?
    @projects = @projects.sort(@sort).page(params[:page]).per(PER_PAGE)
  end

  def trending
    @projects = TrendingProjectsFinder.new.execute(current_user).non_archived.
      page(params[:page]).per(PER_PAGE)
  end

  def starred
    @projects = ProjectsFinder.new.execute(current_user).sort('stars').
      page(params[:page]).per(PER_PAGE)
  end
end
