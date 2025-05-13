# frozen_string_literal: true
#
module Gitlab
  module Tracking
    module Destinations
      class SnowplowMicro < Snowplow
        include ::Gitlab::Utils::StrongMemoize
        extend ::Gitlab::Utils::Override

        delegate :flush, to: :tracker

        DEFAULT_URI = 'http://localhost:9090'

        override :snowplow_options
        def snowplow_options(group)
          super.merge(
            protocol: uri.scheme,
            port: uri.port,
            forceSecureTracker: false # Using camel case as this key will be used only in JavaScript
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
          strong_memoize(:snowplow_uri) do
            base = base_uri
            uri = URI(base)
            uri = URI("http://#{base}") unless %w[http https].include?(uri.scheme)
            uri
          end
        end

        private

        override :cookie_domain
        def cookie_domain
          '.gitlab.com'
        end

        override :protocol
        def protocol
          uri.scheme
        end

        def base_uri
          url = Gitlab.config.snowplow_micro.address
          scheme = Gitlab.config.gitlab.https ? 'https' : 'http'
          "#{scheme}://#{url}"
        rescue GitlabSettings::MissingSetting
          DEFAULT_URI
        end
      end
    end
  end
end
