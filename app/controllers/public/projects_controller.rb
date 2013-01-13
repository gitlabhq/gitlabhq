class Public::ProjectsController < ApplicationController
  skip_before_filter :authenticate_user!,
    :reject_blocked, :set_current_user_for_observers,
    :add_abilities

  layout 'public'

  def index
    @projects = Project.public
    @projects = @projects.includes(:namespace).order("namespaces.path, projects.name ASC").page(params[:page]).per(20)
  end
end
