# frozen_string_literal: true

module Groups
  module Settings
    class CiCdController < Groups::ApplicationController
      include RunnerSetupScripts

      layout 'group_settings'
      skip_cross_project_access_check :show
      before_action :authorize_admin_group!
      before_action :authorize_update_max_artifacts_size!, only: [:update]
      before_action :define_variables, only: [:show]
      before_action :push_licensed_features, only: [:show]

      feature_category :continuous_integration

      NUMBER_OF_RUNNERS_PER_PAGE = 4

      def show
        runners_finder = Ci::RunnersFinder.new(current_user: current_user, group: @group, params: params)
        # We need all runners for count
        @all_group_runners = runners_finder.execute.except(:limit, :offset)
        @group_runners = runners_finder.execute.page(params[:page]).per(NUMBER_OF_RUNNERS_PER_PAGE)

        @sort = runners_finder.sort_key
      end

      def update
        if update_group_service.execute
          flash[:notice] = s_('GroupSettings|Pipeline settings was updated for the group')
        else
          flash[:alert] = s_("GroupSettings|There was a problem updating the pipeline settings: %{error_messages}." % { error_messages: group.errors.full_messages })
        end

        redirect_to group_settings_ci_cd_path
      end

      def reset_registration_token
        @group.reset_runners_token!

        flash[:notice] = _('GroupSettings|New runners registration token has been generated!')
        redirect_to group_settings_ci_cd_path
      end

      def update_auto_devops
        if auto_devops_service.execute
          flash[:notice] = s_('GroupSettings|Auto DevOps pipeline was updated for the group')
        else
          flash[:alert] = s_("GroupSettings|There was a problem updating Auto DevOps pipeline: %{error_messages}." % { error_messages: group.errors.full_messages })
        end

        redirect_to group_settings_ci_cd_path
      end

      def runner_setup_scripts
        private_runner_setup_scripts
      end

      private

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
        return render_404 unless can?(current_user, :admin_group, group)
      end

      def authorize_update_max_artifacts_size!
        return render_404 unless can?(current_user, :update_max_artifacts_size, group)
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
        params.require(:group).permit(:max_artifacts_size)
      end

      # Overridden in EE
      def push_licensed_features
      end
    end
  end
end

Groups::Settings::CiCdController.prepend_mod_with('Groups::Settings::CiCdController')
