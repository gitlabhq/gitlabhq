module Projects
  module Settings
    class RepositoryController < Projects::ApplicationController
      include RepositoryHelper

      before_action :authorize_admin_project!
      before_action :push_rule, only: [:show]
      before_action :remote_mirror, only: [:show]

      def show
        @deploy_keys = DeployKeysPresenter
          .new(@project, current_user: @current_user)

        define_protected_branches
      end      

      private

      def define_protected_branches
        load_protected_branches
        @protected_branch = @project.protected_branches.new
        load_gon_index
      end

      def push_rule
        @push_rule ||= PushRule.find_or_create_by(is_sample: true)
      end

      def remote_mirror
        @remote_mirror = @project.remote_mirrors.first_or_initialize
      end

      def load_protected_branches
        @protected_branches = @project.protected_branches.order(:name).page(params[:page])
      end
    end
  end
end
