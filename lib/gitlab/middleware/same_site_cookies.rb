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
      COOKIE_SEPARATOR = "\n"

      def initialize(app)
        @app = app
      end

      def call(env)
        status, headers, body = @app.call(env)
        result = [status, headers, body]

        set_cookie = headers['Set-Cookie']&.strip

        return result if set_cookie.blank? || !ssl?
        return result if same_site_none_incompatible?(env['HTTP_USER_AGENT'])

        cookies = set_cookie.split(COOKIE_SEPARATOR)

        cookies.each do |cookie|
          next if cookie.blank?

          # Chrome will drop SameSite=None cookies without the Secure
          # flag. If we remove this middleware, we may need to ensure
          # that all cookies set this flag.
          unless SECURE_REGEX.match?(cookie)
            cookie << '; Secure'
          end

          unless SAME_SITE_REGEX.match?(cookie)
            cookie << '; SameSite=None'
          end
        end

        headers['Set-Cookie'] = cookies.join(COOKIE_SEPARATOR)

        result
      end

      private

      # Taken from https://www.chromium.org/updates/same-site/incompatible-clients
      # We use RE2 instead of the browser gem for performance.
      IOS_REGEX = RE2('\(iP.+; CPU .*OS (\d+)[_\d]*.*\) AppleWebKit\/')
      MACOS_REGEX = RE2('\(Macintosh;.*Mac OS X (\d+)_(\d+)[_\d]*.*\) AppleWebKit\/')
      SAFARI_REGEX = RE2('Version\/.* Safari\/')
      CHROMIUM_REGEX = RE2('Chrom(e|ium)')
      CHROMIUM_VERSION_REGEX = RE2('Chrom[^ \/]+\/(\d+)')
      UC_BROWSER_REGEX = RE2('UCBrowser\/')
      UC_BROWSER_VERSION_REGEX = RE2('UCBrowser\/(\d+)\.(\d+)\.(\d+)')

      SECURE_REGEX = RE2(';\s*secure', case_sensitive: false)
      SAME_SITE_REGEX = RE2(';\s*samesite=', case_sensitive: false)

      def ssl?
        Gitlab.config.gitlab.https
      end

      def same_site_none_incompatible?(user_agent)
        return false if user_agent.blank?

        has_webkit_same_site_bug?(user_agent) || drops_unrecognized_same_site_cookies?(user_agent)
      end

      def has_webkit_same_site_bug?(user_agent)
        ios_version?(12, user_agent) ||
          (macos_version?(10, 14, user_agent) && safari?(user_agent))
      end

      def drops_unrecognized_same_site_cookies?(user_agent)
        if uc_browser?(user_agent)
          return !uc_browser_version_at_least?(12, 13, 2, user_agent)
        end

        chromium_based?(user_agent) && chromium_version_between?(51, 66, user_agent)
      end

      def ios_version?(major, user_agent)
        m = IOS_REGEX.match(user_agent)

        return false if m.nil?

        m[1].to_i == major
      end

      def macos_version?(major, minor, user_agent)
        m = MACOS_REGEX.match(user_agent)

        return false if m.nil?

        m[1].to_i == major && m[2].to_i == minor
      end

      def safari?(user_agent)
        SAFARI_REGEX.match?(user_agent)
      end

      def chromium_based?(user_agent)
        CHROMIUM_REGEX.match?(user_agent)
      end

      def chromium_version_between?(from_major, to_major, user_agent)
        m = CHROMIUM_VERSION_REGEX.match(user_agent)

        return false if m.nil?

        version = m[1].to_i
        version >= from_major && version <= to_major
      end

      def uc_browser?(user_agent)
        UC_BROWSER_REGEX.match?(user_agent)
      end

      def uc_browser_version_at_least?(major, minor, build, user_agent)
        m = UC_BROWSER_VERSION_REGEX.match(user_agent)

        return false if m.nil?

        major_version = m[1].to_i
        minor_version = m[2].to_i
        build_version = m[3].to_i

        return major_version > major if major_version != major
        return minor_version > minor if minor_version != minor

        build_version >= build
      end
    end
  end
end
