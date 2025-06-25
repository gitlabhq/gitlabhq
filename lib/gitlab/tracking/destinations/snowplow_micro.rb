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

        def initialize
          super(DestinationConfiguration.snowplow_micro_configuration)
        end

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
      end
    end
  end
end
