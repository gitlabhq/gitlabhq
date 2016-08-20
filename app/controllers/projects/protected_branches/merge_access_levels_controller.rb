module Projects
  module ProtectedBranches
    class MergeAccessLevelsController < ProtectedBranches::ApplicationController
      before_action :load_protected_branch, only: [:destroy]

      def destroy
        @merge_access_level = @protected_branch.merge_access_levels.find(params[:id])
        @merge_access_level.destroy

        redirect_to namespace_project_protected_branch_path(@project.namespace, @project, @protected_branch),
                    notice: "Successfully deleted. #{@merge_access_level.humanize} will not be able to merge into this protected branch."
      end
    end
  end
end
