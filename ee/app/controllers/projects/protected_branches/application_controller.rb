class Projects::ProtectedBranches::ApplicationController < Projects::ApplicationController
  protected

  def load_protected_branch
    @protected_branch = @project.protected_branches.find(params[:protected_branch_id])
  end
end
