# frozen_string_literal: true

module Gitlab
  module Tracking
    module Destinations
      class DestinationConfiguration
        PRODUCT_USAGE_EVENT_COLLECT_ENDPOINT = 'https://events.gitlab.net'
        PRODUCT_USAGE_EVENT_COLLECT_ENDPOINT_STG = 'https://events-stg.gitlab.net'
        SNOWPLOW_MICRO_DEFAULT_URI = 'http://localhost:9090'

        class << self
          def snowplow_configuration
            new(snowplow_uri)
          end

          def snowplow_micro_configuration
            new(snowplow_micro_uri)
          end

          private

          def snowplow_micro_uri
            url = Gitlab.config.snowplow_micro.address
            scheme = Gitlab.config.gitlab.https ? 'https' : 'http'
            URI("#{scheme}://#{url}")
          rescue GitlabSettings::MissingSetting
            URI(SNOWPLOW_MICRO_DEFAULT_URI)
          end

          def snowplow_uri
            if Gitlab::CurrentSettings.snowplow_enabled?
              hostname = Gitlab::CurrentSettings.snowplow_collector_hostname
              addressable_uri = Addressable::URI.heuristic_parse(convert_if_bare_hostname(hostname), scheme: 'https')
              URI(addressable_uri.to_s)
            elsif Feature.enabled?(:use_staging_endpoint_for_product_usage_events, :instance)
              URI(PRODUCT_USAGE_EVENT_COLLECT_ENDPOINT_STG)
            else
              URI(PRODUCT_USAGE_EVENT_COLLECT_ENDPOINT)
            end
          end

          def convert_if_bare_hostname(hostname)
            return hostname if hostname.blank? || hostname.include?('/') || hostname.include?('.')

            "//#{hostname}"
          end
        end

        attr_reader :uri

        def initialize(collector_uri)
          @uri = collector_uri
        end

        def hostname
          return uri.host unless uri.port
          return uri.host if default_port?

          "#{uri.host}:#{uri.port}"
        end

        def port
          uri.port
        end

        def protocol
          uri.scheme
        end

        private

        def default_port?
          (uri.scheme == 'https' && uri.port == 443) ||
            (uri.scheme == 'http' && uri.port == 80)
        end
      end
    end
  end
end
