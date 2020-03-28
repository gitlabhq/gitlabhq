# frozen_string_literal: true

# This middleware sets the SameSite directive to None on all cookies.
# It also adds the Secure directive if HTTPS is enabled.
#
# Chrome v80, rolled out in March 2020, treats any cookies without the
# SameSite directive set as though they are SameSite=Lax
# (https://www.chromestatus.com/feature/5088147346030592). This is a
# breaking change from the previous default behavior, which was to treat
# those cookies as SameSite=None.
#
# This middleware is needed until we upgrade to Rack v2.1.0+
# (https://github.com/rack/rack/commit/c859bbf7b53cb59df1837612a8c330dfb4147392)
# and a version of Rails that has native support
# (https://github.com/rails/rails/commit/7ccaa125ba396d418aad1b217b63653d06044680).
#
module Gitlab
  module Middleware
    class SameSiteCookies
      COOKIE_SEPARATOR = "\n".freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        status, headers, body = @app.call(env)
        result = [status, headers, body]

        set_cookie = headers['Set-Cookie']&.strip

        return result if set_cookie.blank? || !ssl?

        cookies = set_cookie.split(COOKIE_SEPARATOR)

        cookies.each do |cookie|
          next if cookie.blank?

          # Chrome will drop SameSite=None cookies without the Secure
          # flag. If we remove this middleware, we may need to ensure
          # that all cookies set this flag.
          if ssl? && !(cookie =~ /;\s*secure/i)
            cookie << '; Secure'
          end

          unless cookie =~ /;\s*samesite=/i
            cookie << '; SameSite=None'
          end
        end

        headers['Set-Cookie'] = cookies.join(COOKIE_SEPARATOR)

        result
      end

      private

      def ssl?
        Gitlab.config.gitlab.https
      end
    end
  end
end
