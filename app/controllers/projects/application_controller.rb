class Projects::ApplicationController < ApplicationController
  before_filter :project
  before_filter :repository
  layout :determine_layout

  def authenticate_user!
    # Restrict access to Projects area only
    # for non-signed users
    if !current_user
      id = params[:project_id] || params[:id]
      @project = Project.find_with_namespace(id)

      return if @project && @project.public?
    end

    super
  end

  def determine_layout
    if current_user
      'projects'
    else
      'public_projects'
    end
  end

  def require_branch_head
    unless @repository.branch_names.include?(@ref)
      redirect_to project_tree_path(@project, @ref), notice: "This action is not allowed unless you are on top of a branch"
    end
  end

  protected

  def changes_successful_action(result, redirect_path)
    if result[:status] == :success
      flash[:notice] = changes_successful_action_message
      redirect_to redirect_path
    else
      flash[:alert] = result[:message]
      render :show
    end
  end

  def changes_successful_action_message
    'Your changes have been successfully committed'
  end
end
