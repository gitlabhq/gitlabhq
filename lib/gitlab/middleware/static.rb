module Gitlab
  module Middleware
    class Static < ActionDispatch::Static
      UPLOADS_REGEX = %r{\A/uploads(/|\z)}.freeze

      def call(env)
        return @app.call(env) if env['PATH_INFO'] =~ UPLOADS_REGEX

        super
      end
    end
  end
end
