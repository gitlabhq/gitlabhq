class Projects::ApplicationController < ApplicationController
  skip_before_filter :authenticate_user!
  before_filter :project
  before_filter :repository
  layout :determine_layout

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
end
