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

  def set_filter_variables(collection)
    params[:sort] ||= 'newest'
    params[:scope] = 'all' if params[:scope].blank?
    params[:state] = 'opened' if params[:state].blank?

    @sort = params[:sort].humanize

    assignee_id = params[:assignee_id]
    author_id = params[:author_id]
    milestone_id = params[:milestone_id]

    if assignee_id.present? && !assignee_id.to_i.zero?
      @assignee = @project.team.find(assignee_id)
    end

    if author_id.present? && !author_id.to_i.zero?
      @author = @project.team.find(assignee_id)
    end

    if milestone_id.present? && !milestone_id.to_i.zero?
      @milestone = @project.milestones.find(milestone_id)
    end

    @assignees = User.where(id: collection.pluck(:assignee_id))
    @authors = User.where(id: collection.pluck(:author_id))
  end
end
