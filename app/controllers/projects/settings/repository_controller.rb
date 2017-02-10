module Projects
  module Settings
    class RepositoryController < Projects::ApplicationController
      include RepositoryHelper

      before_action :authorize_admin_project!
      before_action :load_protected_branches, only: [:show]

      def show
        @deploy_keys = DeployKeysPresenter
          .new(@project, current_user: @current_user)

        define_protected_branches_controller
      end

      def load_protected_branches
        @protected_branches = @project.protected_branches.order(:name).page(params[:page])
      end

      private

      def define_protected_branches_controller
        @protected_branch = @project.protected_branches.new
        load_gon_index
      end
    end
  end
end
