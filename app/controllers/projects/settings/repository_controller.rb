module Projects
  module Settings
    class RepositoryController < Projects::ApplicationController
      include RepositoryHelper

      before_action :authorize_admin_project!
      before_action :load_protected_branches, only: [:show]

      def show
        define_deploy_keys_variables
        define_protected_branches_controller
      end

      def load_protected_branches
        @protected_branches = @project.protected_branches.order(:name).page(params[:page])
      end

      def set_index_vars
        @enabled_keys           ||= @project.deploy_keys

        @available_keys         ||= current_user.accessible_deploy_keys - @enabled_keys
        @available_project_keys ||= current_user.project_deploy_keys - @enabled_keys
        @available_public_keys  ||= DeployKey.are_public - @enabled_keys

        # Public keys that are already used by another accessible project are already
        # in @available_project_keys.
        @available_public_keys -= @available_project_keys
      end

      private

      def define_deploy_keys_variables
        @key = DeployKey.new
        set_index_vars
      end

      def define_protected_branches_controller
        @protected_branch = @project.protected_branches.new
        load_gon_index(@project)
      end
    end
  end
end
