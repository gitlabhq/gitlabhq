# frozen_string_literal: true

module Gitlab
  module Puma
    class ErrorHandler
      PROD_ERROR_MESSAGE = "An error has occurred and reported in the system's low-level error handler."
      DEV_ERROR_MESSAGE = <<~MSG
        Server Error: An error has been caught by Puma's low-level error handler.
        Read the Puma section of the troubleshooting docs for next steps - https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/troubleshooting/index.md#puma.
      MSG

      def initialize(is_production)
        @is_production = is_production
      end

      def execute(ex, env, status_code)
        # Puma v6.4.0 added the status_code argument in
        # https://github.com/puma/puma/pull/3094
        status_code ||= 500

        Gitlab::ErrorTracking.track_exception(
          ex,
          { puma_env: env, status_code: status_code },
          { handler: 'puma_low_level' }
        )

        # note the below is just a Rack response
        [status_code, {}, message]
      end

      private

      def message
        if @is_production
          PROD_ERROR_MESSAGE
        else
          DEV_ERROR_MESSAGE
        end
      end
    end
  end
end
