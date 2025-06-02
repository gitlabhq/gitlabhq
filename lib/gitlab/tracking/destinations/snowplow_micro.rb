# frozen_string_literal: true
#
module Gitlab
  module Tracking
    module Destinations
      class SnowplowMicro < Snowplow
        include ::Gitlab::Utils::StrongMemoize
        extend ::Gitlab::Utils::Override

        delegate :flush, to: :tracker

        COOKIE_DOMAIN = '.gitlab.com'
        DEFAULT_URI = 'http://localhost:9090'

        override :snowplow_options
        def snowplow_options(group)
          # Using camel case as these keys will be used only in JavaScript
          super.merge(
            protocol: protocol,
            port: uri.port,
            forceSecureTracker: false,
            cookieDomain: COOKIE_DOMAIN
          )
        end

        override :enabled?
        def enabled?
          true
        end

        override :hostname
        def hostname
          "#{uri.host}:#{uri.port}"
        end

        def uri
          url = Gitlab.config.snowplow_micro.address
          scheme = Gitlab.config.gitlab.https ? 'https' : 'http'
          URI("#{scheme}://#{url}")
        rescue GitlabSettings::MissingSetting
          URI(DEFAULT_URI)
        end
        strong_memoize_attr :uri

        private

        override :protocol
        def protocol
          uri.scheme
        end
      end
    end
  end
end
