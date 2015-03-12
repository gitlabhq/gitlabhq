module Gitlab
  module Middleware
    class Timeout < Rack::Timeout
      GRACK_REGEX = /[-\/\w\.]+\.git\//.freeze

      def call(env)
        return @app.call(env) if env['PATH_INFO'] =~ GRACK_REGEX

        super
      end
    end
  end
end
