# frozen_string_literal: true

module Groups
  module Settings
    class CiCdController < Groups::ApplicationController
      layout 'group_settings'
      skip_cross_project_access_check :show
      before_action :authorize_admin_group!, except: :show
      before_action :authorize_show_cicd_settings!, only: :show
      before_action :authorize_update_max_artifacts_size!, only: [:update]
      before_action :define_variables, only: [:show]
      before_action :push_licensed_features, only: [:show]
      before_action :assign_variables_to_gon, only: [:show]

      feature_category :continuous_integration

      before_action do
        push_frontend_feature_flag(:ci_variables_pages, current_user)
      end

      urgency :low

      def show
        @entity = :group
        @variable_limit = ::Plan.default.actual_limits.group_ci_variables
      end

      def update
        if update_group_service.execute
          flash[:notice] = s_('GroupSettings|Group CI/CD settings were successfully updated.')
        else
          flash[:alert] =
            format(s_("GroupSettings|There was a problem updating the group CI/CD settings: %{error_messages}."),
              error_messages: group.errors.full_messages)
        end

        redirect_to group_settings_ci_cd_path
      end

      def update_auto_devops
        if auto_devops_service.execute
          flash[:notice] = s_('GroupSettings|Auto DevOps pipeline was updated for the group')
        else
          flash[:alert] =
            format(s_("GroupSettings|There was a problem updating Auto DevOps pipeline: %{error_messages}."),
              error_messages: group.errors.full_messages)
        end

        redirect_to group_settings_ci_cd_path
      end

      private

      def authorize_show_cicd_settings!
        return if can_any?(current_user, [
          :admin_cicd_variables,
          :admin_protected_environments,
          :admin_runner
        ], group)

        access_denied!
      end

      def define_variables
        define_ci_variables
      end

      def define_ci_variables
        @variable = Ci::GroupVariable.new(group: group)
          .present(current_user: current_user)
        @variables = group.variables.order_key_asc
          .map { |variable| variable.present(current_user: current_user) }
      end

      def authorize_admin_group!
        render_404 unless can?(current_user, :admin_group, group)
      end

      def authorize_update_max_artifacts_size!
        if update_group_params.has_key?(:max_artifacts_size) && !can?(current_user, :update_max_artifacts_size, group)
          render_404
        end
      end

      def auto_devops_params
        params.require(:group).permit(:auto_devops_enabled)
      end

      def auto_devops_service
        Groups::AutoDevopsService.new(group, current_user, auto_devops_params)
      end

      def update_group_service
        Groups::UpdateService.new(group, current_user, update_group_params)
      end

      def update_group_params
        params.require(:group).permit(:max_artifacts_size, :allow_runner_registration_token)
      end

      # Overridden in EE
      def push_licensed_features; end

      # Overridden in EE
      def assign_variables_to_gon; end
    end
  end
end

Groups::Settings::CiCdController.prepend_mod_with('Groups::Settings::CiCdController')
