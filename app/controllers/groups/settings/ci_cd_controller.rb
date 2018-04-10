module Groups
  module Settings
    class CiCdController < Groups::ApplicationController
      skip_cross_project_access_check :show
      before_action :authorize_admin_pipeline!

      def show
        define_secret_variables
      end

      private

      def define_secret_variables
        @variable = Ci::GroupVariable.new(group: group)
          .present(current_user: current_user)
        @variables = group.variables.order_key_asc
          .map { |variable| variable.present(current_user: current_user) }
      end

      def authorize_admin_pipeline!
        return render_404 unless can?(current_user, :admin_pipeline, group)
      end
    end
  end
end
