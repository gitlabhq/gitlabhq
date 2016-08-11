module Projects
  module ProtectedBranches
    class PushAccessLevelsController < Projects::ProtectedBranches::ApplicationController
      before_action :load_protected_branch

      def destroy
        @push_access_level = @protected_branch.push_access_levels.find(params[:id])
        @push_access_level.destroy

        flash[:notice] = "Successfully deleted. #{@push_access_level.humanize} will not be able to push to this protected branch."
        redirect_to namespace_project_protected_branch_path(@project.namespace, @project, @protected_branch)
      end
    end
  end
end
