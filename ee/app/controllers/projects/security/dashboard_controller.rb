module Projects
  module Security
    class DashboardController < Projects::ApplicationController
      before_action :ensure_security_features_enabled
      before_action :authorize_read_project_security_dashboard!

      def show
        @pipeline = @project.latest_pipeline_with_security_reports
      end

      private

      def ensure_security_features_enabled
        render_404 unless @project.security_reports_feature_available?
      end
    end
  end
end
