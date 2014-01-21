class Public::ProjectsController < ApplicationController
  skip_before_filter :authenticate_user!,
                     :reject_blocked, :set_current_user_for_observers,
                     :add_abilities

  layout 'public'

  def index
    @projects = Project.public_or_internal_only(current_user)
    @projects = @projects.search(params[:search]) if params[:search].present?
    @projects = @projects.sort(@sort = params[:sort])
    @projects = @projects.includes(:namespace).page(params[:page]).per(20)
  end
end
