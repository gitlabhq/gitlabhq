# frozen_string_literal: true

module Gitlab
  module Middleware
    class IpAddress
      def initialize(app)
        @app = app
      end

      def call(env)
        return @app.call(env) if %r{^/api/v\d+/internal/}.match?(env['PATH_INFO'])

        ::Gitlab::IpAddressState.with(env['action_dispatch.remote_ip'].to_s) do # rubocop: disable CodeReuse/ActiveRecord -- not ActiveRecord
          @app.call(env)
        end
      end
    end
  end
end
