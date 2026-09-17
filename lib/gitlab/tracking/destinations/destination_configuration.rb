# frozen_string_literal: true

module Gitlab
  module Tracking
    module Destinations
      class DestinationConfiguration
        PRODUCT_USAGE_EVENT_COLLECT_ENDPOINT = 'https://events.gitlab.net'
        PRODUCT_USAGE_EVENT_COLLECT_ENDPOINT_STG = 'https://events-stg.gitlab.net'
        BILLING_COLLECT_ENDPOINT = 'https://billing.prdsub.gitlab.net'
        BILLING_COLLECT_ENDPOINT_STG = 'https://billing.stgsub.gitlab.net'
        SNOWPLOW_MICRO_DEFAULT_URI = 'http://localhost:9091'

        class << self
          def snowplow_configuration
            new(snowplow_uri)
          end

          def snowplow_micro_configuration
            new(snowplow_micro_uri)
          end

          def billing_configuration
            new(billing_uri, app_id_suffix: '_billing', billing: true)
          end

          def non_production_environment?
            host = Gitlab.config.gitlab.host
            is_gitlab_qa_instance = host.start_with?('gitlab') && host.end_with?('.test')

            Gitlab.staging? || is_gitlab_qa_instance || staging_customer_portal?
          end

          private

          # An instance whose CUSTOMER_PORTAL_URL points at the staging Customers Portal is a staging
          # instance for billing purposes
          def staging_customer_portal?
            configured_url = ENV['CUSTOMER_PORTAL_URL'].presence
            return false unless configured_url

            staging_url = ENV['STAGING_CUSTOMER_PORTAL_URL'].presence ||
              Gitlab::SubscriptionPortal.default_staging_customer_portal_url

            configured_url.chomp('/') == staging_url.chomp('/')
          end

          def snowplow_micro_uri
            url = Gitlab.config.snowplow_micro.address
            URI("http://#{url}")
          rescue Gitlab::Configs::MissingConfig
            URI(SNOWPLOW_MICRO_DEFAULT_URI)
          end

          def snowplow_uri
            if Gitlab::CurrentSettings.snowplow_enabled?
              hostname = Gitlab::CurrentSettings.snowplow_collector_hostname
              addressable_uri = Addressable::URI.heuristic_parse(convert_if_bare_hostname(hostname), scheme: 'https')
              URI(addressable_uri.to_s)
            elsif non_production_environment?
              URI(PRODUCT_USAGE_EVENT_COLLECT_ENDPOINT_STG)
            else
              URI(PRODUCT_USAGE_EVENT_COLLECT_ENDPOINT)
            end
          end

          def billing_uri
            if non_production_environment?
              URI(BILLING_COLLECT_ENDPOINT_STG)
            else
              URI(BILLING_COLLECT_ENDPOINT)
            end
          end

          def convert_if_bare_hostname(hostname)
            return hostname if hostname.blank? || hostname.include?('/') || hostname.include?('.')

            "//#{hostname}"
          end
        end

        attr_reader :uri, :app_id_suffix

        def initialize(collector_uri, app_id_suffix: nil, billing: false)
          @uri = collector_uri
          @billing = billing
          @app_id_suffix = app_id_suffix
        end

        def billing?
          @billing
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
