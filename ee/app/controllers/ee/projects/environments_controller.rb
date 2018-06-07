module EE
  module Projects
    module EnvironmentsController
      extend ActiveSupport::Concern

      prepended do
        before_action :authorize_read_pod_logs!, only: [:logs]
        before_action :environment_ee, only: [:logs]
      end

      def logs
        respond_to do |format|
          format.html
          format.json do
            ::Gitlab::PollingInterval.set_header(response, interval: 3_000)

            render json: {
              logs: pod_logs.strip.split("\n").as_json
            }
          end
        end
      end

      private

      def environment_ee
        environment
      end

      def pod_logs
        @pod_logs ||= environment.deployment_platform.read_pod_logs(params[:pod_name])
      end
    end
  end
end
