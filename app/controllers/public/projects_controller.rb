class Public::ProjectsController < ApplicationController
  skip_before_filter :authenticate_user!,
    :reject_blocked, :set_current_user_for_observers,
    :add_abilities

  layout 'public'

  def index
    @projects = Project.public_only
    @projects = @projects.search(params[:search]) if params[:search].present?
    @projects = @projects.includes(:namespace).order("namespaces.path, projects.name ASC").page(params[:page]).per(20)
  end

  def show
    @project = Project.public_only.find_with_namespace(params[:id])
    render_404 and return unless @project

    @repository = @project.repository
    @recent_tags = @repository.tags.first(10)

    @commit = @repository.commit(params[:ref])
    @tree = Tree.new(@repository, @commit.id)
  end
end
