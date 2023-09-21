# frozen_string_literal: true

module Gitlab
  module Middleware
    class Static < ActionDispatch::Static
      UPLOADS_REGEX = %r{\A/uploads(/|\z)}

      def call(env)
        return @app.call(env) if UPLOADS_REGEX.match?(env['PATH_INFO'])

        super
      end
    end
  end
end
