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
    end
  end
end
