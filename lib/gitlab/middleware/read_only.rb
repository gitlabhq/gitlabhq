module Gitlab
  module Middleware
    class ReadOnly
      API_VERSIONS = (3..4)

      def self.internal_routes
        @internal_routes ||=
          API_VERSIONS.map { |version| "api/v#{version}/internal" }
      end

      def initialize(app)
        @app = app
      end

      def call(env)
        ReadOnly::Controller.new(@app, env).call
      end
    end
  end
end
