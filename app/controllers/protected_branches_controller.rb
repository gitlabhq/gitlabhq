class ProtectedBranchesController < ApplicationController
  before_filter :project

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_project!
  before_filter :require_non_empty_project

  layout "project"

  def index
    @branches = @project.protected_branches.all
    @protected_branch = @project.protected_branches.new
  end

  def create
    @project.protected_branches.create(params[:protected_branch])
    redirect_to project_protected_branches_path(@project)
  end

  def destroy
  end
end
