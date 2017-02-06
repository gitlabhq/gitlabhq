# This Rack middleware is intended to proxy the webpack assets directory to the
# webpack-dev-server.  It is only intended for use in development.

module Gitlab
  module Middleware
    class WebpackProxy < Rack::Proxy
      def initialize(app = nil, opts = {})
        @proxy_host = opts.fetch(:proxy_host, 'localhost')
        @proxy_port = opts.fetch(:proxy_port, 3808)
        @proxy_path = opts[:proxy_path] if opts[:proxy_path]
        super(app, opts)
      end

      def perform_request(env)
        unless @proxy_path && env['PATH_INFO'].start_with?("/#{@proxy_path}")
          return @app.call(env)
        end

        env['HTTP_HOST'] = "#{@proxy_host}:#{@proxy_port}"
        super(env)
      end
    end
  end
end
