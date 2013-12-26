class Public::ProjectsController < ApplicationController
  skip_before_filter :authenticate_user!,
                     :reject_blocked, :set_current_user_for_observers,
                     :add_abilities

  layout 'public'

  def index
    @projects = Project.public_or_internal_only(current_user)
    @projects = @projects.search(params[:search]) if params[:search].present?
    @projects = case params[:sort]
                when 'newest' then @projects.order('created_at DESC')
                when 'oldest' then @projects.order('created_at ASC')
                when 'recently_updated' then @projects.order('updated_at DESC')
                when 'last_updated' then @projects.order('updated_at ASC')
                else @projects.order("namespaces.path, projects.name ASC")
                end
    @projects = @projects.includes(:namespace).page(params[:page]).per(20)
  end
end
