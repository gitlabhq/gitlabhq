# frozen_string_literal: true

module Gitlab
  module Middleware
    # IamServiceProxy proxies requests from /iam-service/* to the IAM service.
    # This middleware is DEVELOPMENT ONLY.
    #
    # This allows GitLab to access IAM via HTTPS on the same host, avoiding
    # SSL verification issues when IAM is running on HTTP.
    #
    # Example: https://gdk.com:3000/iam-service/.well-known/openid-configuration
    #          => http://localhost:8084/.well-known/openid-configuration
    class IamServiceProxy < Rack::Proxy
      IAM_SERVICE_PATH_PREFIX = '/iam-service'

      def initialize(app = nil, opts = {})
        backend_url = begin
          Authn::IamAuthService.url
        rescue Authn::IamAuthService::ConfigurationError
          nil
        end

        super(app, backend: backend_url, **opts)
      end

      def perform_request(env)
        if @backend.present? && Authn::IamAuthService.enabled? && env['PATH_INFO'].start_with?(IAM_SERVICE_PATH_PREFIX)

          # Remove /iam-service prefix from path
          env['PATH_INFO'] = env['PATH_INFO'].sub(IAM_SERVICE_PATH_PREFIX, '')
          env['PATH_INFO'] = '/' if env['PATH_INFO'].empty?

          super
        else
          @app.call(env)
        end
      end
    end
  end
end
