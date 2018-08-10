module EE
  module Projects
    module EnvironmentsController
      extend ActiveSupport::Concern

      prepended do
        before_action :authorize_read_pod_logs!, only: [:logs]
        before_action :environment_ee, only: [:logs]
        before_action :authorize_create_environment_terminal!, only: [:terminal]
      end

      def logs
        respond_to do |format|
          format.html
          format.json do
            ::Gitlab::PollingInterval.set_header(response, interval: 3_000)

            render json: {
              logs: pod_logs.strip.split("\n").as_json,
              pods: environment.pod_names
            }
          end
        end
      end

      private

      def environment_ee
        environment
      end

      def pod_logs
        environment.deployment_platform.read_pod_logs(params[:pod_name])
      end

      def authorize_create_environment_terminal!
        return render_404 unless can?(current_user, :create_environment_terminal, environment)
      end
    end
  end
end
