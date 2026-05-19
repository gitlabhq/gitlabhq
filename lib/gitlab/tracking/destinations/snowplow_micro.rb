# frozen_string_literal: true

module Gitlab
  module Tracking
    module Destinations
      class SnowplowMicro < Snowplow
        include ::Gitlab::Utils::StrongMemoize
        extend ::Gitlab::Utils::Override

        delegate :flush, to: :tracker

        COOKIE_DOMAIN = '.gitlab.com'

        def initialize
          super(DestinationConfiguration.snowplow_micro_configuration)
        end

        override :snowplow_options
        def snowplow_options
          # Using camel case as these keys will be used only in JavaScript
          # Do not pass a separate `port` option here. The base class `hostname`
          # already includes the port for non-default ports (e.g. "localhost:9091")
          # and the Snowplow JS tracker unconditionally appends `:port` when the
          # option is present, which produces broken URLs like "host:9091:9091".
          super.merge(
            protocol: protocol,
            forceSecureTracker: false,
            cookieDomain: COOKIE_DOMAIN
          )
        end
      end
    end
  end
end
