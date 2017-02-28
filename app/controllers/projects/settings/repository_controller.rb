module Projects
  module Settings
    class RepositoryController < Projects::ApplicationController
      before_action :authorize_admin_project!

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

      def load_protected_branches
        @protected_branches = @project.protected_branches.order(:name).page(params[:page])
      end

      def access_levels_options
        {
          push_access_levels: {
            "Roles" => ProtectedBranch::PushAccessLevel.human_access_levels.map do |id, text| 
              { id: id, text: text, before_divider: true } 
            end
          },
          merge_access_levels: {
            "Roles" => ProtectedBranch::MergeAccessLevel.human_access_levels.map do |id, text| 
              { id: id, text: text, before_divider: true } 
            end
          }
        }
      end

      def load_gon_index
        open_branches = @project.open_branches.map { |br| { text: br.name, id: br.name, title: br.name } }
        params = { open_branches: open_branches }
        gon.push(params.merge(access_levels_options))
      end
    end
  end
end
