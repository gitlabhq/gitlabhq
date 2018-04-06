module Projects
  module Settings
    class RepositoryController < Projects::ApplicationController
      before_action :authorize_admin_project!

      def show
        render_show
      end

      def create_deploy_token
        @new_deploy_token = DeployTokens::CreateService.new(@project, current_user, deploy_token_params).execute

        if @new_deploy_token.persisted?
          flash.now[:notice] = s_('DeployTokens|Your new project deploy token has been created.')
        end

        render_show
      end

      private

      def render_show
        @deploy_keys = DeployKeysPresenter.new(@project, current_user: current_user)
        @deploy_tokens = DeployTokensPresenter.new(@project.deploy_tokens.active, current_user: current_user, project: project)

        define_deploy_token
        define_protected_refs

        render 'show'
      end

      def define_protected_refs
        @protected_branches = @project.protected_branches.order(:name).page(params[:page])
        @protected_tags = @project.protected_tags.order(:name).page(params[:page])
        @protected_branch = @project.protected_branches.new
        @protected_tag = @project.protected_tags.new

        @protected_branches_count = @protected_branches.reduce(0) { |sum, branch| sum + branch.matching(@project.repository.branches).size }
        @protected_tags_count = @protected_tags.reduce(0) { |sum, tag| sum + tag.matching(@project.repository.tags).size }

        load_gon_index
      end

      def access_levels_options
        {
          create_access_levels: levels_for_dropdown,
          push_access_levels: levels_for_dropdown,
          merge_access_levels: levels_for_dropdown
        }
      end

      def levels_for_dropdown
        roles = ProtectedRefAccess::HUMAN_ACCESS_LEVELS.map do |id, text|
          { id: id, text: text, before_divider: true }
        end
        { roles: roles }
      end

      def protectable_tags_for_dropdown
        { open_tags: ProtectableDropdown.new(@project, :tags).hash }
      end

      def protectable_branches_for_dropdown
        { open_branches: ProtectableDropdown.new(@project, :branches).hash }
      end

      def load_gon_index
        gon.push(protectable_tags_for_dropdown)
        gon.push(protectable_branches_for_dropdown)
        gon.push(access_levels_options)
      end

      def define_deploy_token
        @new_deploy_token ||= DeployToken.new
      end

      def deploy_token_params
        params.require(:deploy_token).permit(:name, :expires_at, :read_repository, :read_registry)
      end
    end
  end
end
