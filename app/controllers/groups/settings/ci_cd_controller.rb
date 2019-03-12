# frozen_string_literal: true

module Groups
  module Settings
    class CiCdController < Groups::ApplicationController
      skip_cross_project_access_check :show
      before_action :authorize_admin_group!

      def show
        define_ci_variables
      end

      def reset_registration_token
        @group.reset_runners_token!

        flash[:notice] = 'New runners registration token has been generated!'
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

      private

      def define_ci_variables
        @variable = Ci::GroupVariable.new(group: group)
          .present(current_user: current_user)
        @variables = group.variables.order_key_asc
          .map { |variable| variable.present(current_user: current_user) }
      end

      def authorize_admin_group!
        return render_404 unless can?(current_user, :admin_group, group)
      end

      def auto_devops_params
        params.require(:group).permit(:auto_devops_enabled)
      end

      def auto_devops_service
        Groups::AutoDevopsService.new(group, current_user, auto_devops_params)
      end
    end
  end
end
