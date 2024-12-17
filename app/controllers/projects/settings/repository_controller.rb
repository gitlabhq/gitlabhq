# frozen_string_literal: true

module Projects
  module Settings
    class RepositoryController < Projects::ApplicationController
      layout 'project_settings'
      before_action :authorize_admin_project!
      before_action :define_variables, only: [:create_deploy_token]

      before_action do
        push_frontend_feature_flag(:edit_branch_rules, @project)
        push_frontend_feature_flag(:branch_rule_squash_settings, @project)
        push_frontend_ability(ability: :admin_project, resource: @project, user: current_user)
        push_frontend_ability(ability: :admin_protected_branch, resource: @project, user: current_user)
      end

      feature_category :source_code_management, [:show, :cleanup, :update]
      feature_category :continuous_delivery, [:create_deploy_token]
      urgency :low, [:show, :create_deploy_token]

      def show
        render_show
      end

      def cleanup
        bfg_object_map = params.require(:project).require(:bfg_object_map)
        result = Projects::CleanupService.enqueue(project, current_user, bfg_object_map)

        if result[:status] == :success
          flash[:notice] = _('Repository cleanup has started. You will receive an email once the cleanup operation is complete.')
        else
          flash[:alert] = result.fetch(:message, _('Failed to upload object map file'))
        end

        redirect_to project_settings_repository_path(project)
      end

      def create_deploy_token
        result = Projects::DeployTokens::CreateService.new(@project, current_user, deploy_token_params).execute

        if result[:status] == :success
          @created_deploy_token = result[:deploy_token]
          respond_to do |format|
            format.json do
              # IMPORTANT: It's a security risk to expose the token value more than just once here!
              json = API::Entities::DeployTokenWithToken.represent(@created_deploy_token).as_json
              render json: json, status: result[:http_status]
            end
            format.html do
              flash.now[:notice] = s_('DeployTokens|Your new project deploy token has been created.')
              render :show
            end
          end
        else
          @new_deploy_token = result[:deploy_token]
          respond_to do |format|
            format.json { render json: { message: result[:message] }, status: result[:http_status] }
            format.html do
              flash.now[:alert] = result[:message]
              render :show
            end
          end
        end
      end

      def update
        result = ::Projects::UpdateService.new(@project, current_user, project_params).execute

        if result[:status] == :success
          flash[:notice] = _("Project settings were successfully updated.")
        else
          flash[:alert] = result[:message]
          @project.reset
        end

        redirect_to project_settings_repository_path(project)
      end

      private

      def render_show
        define_variables

        render 'show'
      end

      def define_variables
        @deploy_keys = DeployKeysPresenter.new(@project, current_user: current_user)

        define_deploy_token_variables
        define_protected_refs
        remote_mirror
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def define_protected_refs
        @protected_branches = fetch_protected_branches(@project).preload_access_levels
        @protected_tags = @project.protected_tags.preload_access_levels.order(:name).page(pagination_params[:page])
        @protected_branch = @project.protected_branches.new
        @protected_tag = @project.protected_tags.new

        @protected_tags_count = @protected_tags.reduce(0) { |sum, tag| sum + tag.matching(@project.repository.tag_names).size }
        load_gon_index
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def fetch_protected_branches(project)
        project.protected_branches.sorted_by_name.page(pagination_params[:page])
      end

      def remote_mirror
        @remote_mirror = project.remote_mirrors.first_or_initialize
      end

      def deploy_token_params
        params.require(:deploy_token).permit(:name, :expires_at, :read_repository, :read_registry, :write_registry, :read_package_registry, :write_package_registry, :username)
      end

      def project_params
        params.require(:project).permit(project_params_attributes)
      end

      def project_params_attributes
        [
          :issue_branch_template,
          :default_branch,
          :autoclose_referenced_issues
        ]
      end

      def protectable_tags_for_dropdown
        { open_tags: ProtectableDropdown.new(@project, :tags).hash }
      end

      def protectable_branches_for_dropdown
        { open_branches: ProtectableDropdown.new(@project, :branches).hash }
      end

      def define_deploy_token_variables
        @deploy_tokens = @project.deploy_tokens.active

        @new_deploy_token ||= DeployToken.new
      end

      def load_gon_index
        gon.push(protectable_tags_for_dropdown)
        gon.push(protectable_branches_for_dropdown)
        gon.push(helpers.protected_access_levels_for_dropdowns)
        gon.push(current_project_id: project.id) if project
      end
    end
  end
end

Projects::Settings::RepositoryController.prepend_mod_with('Projects::Settings::RepositoryController')
