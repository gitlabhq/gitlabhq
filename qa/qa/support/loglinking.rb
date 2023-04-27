# frozen_string_literal: true

module QA
  module Support
    module Loglinking
      # Static address variables declared for mapping environment to logging URLs
      STAGING_ADDRESS            = 'https://staging.gitlab.com'
      STAGING_REF_ADDRESS        = 'https://staging-ref.gitlab.com'
      PRODUCTION_ADDRESS         = 'https://gitlab.com'
      PRE_PROD_ADDRESS           = 'https://pre.gitlab.com'

      # Text titles used for labeling various IDs and URLs
      CORRELATION_ID_TITLE       = 'Correlation Id:'
      SENTRY_URL_TITLE           = 'Sentry Url:'
      KIBANA_DISCOVER_URL_TITLE  = 'Kibana - Discover Url:'
      KIBANA_DASHBOARD_URL_TITLE = 'Kibana - Dashboard Url:'

      class << self
        def failure_metadata(correlation_id)
          return if correlation_id.blank?

          errors = ["#{CORRELATION_ID_TITLE} #{correlation_id}"]

          env = logging_environment

          sentry = QA::Support::SystemLogs::Sentry.new(env, correlation_id)
          sentry_url = sentry.url

          kibana = QA::Support::SystemLogs::Kibana.new(env, correlation_id)
          kibana_discover_url = kibana.discover_url
          kibana_dashboard_url = kibana.dashboard_url

          errors << "#{SENTRY_URL_TITLE} #{sentry_url}" if sentry_url
          errors << "#{KIBANA_DISCOVER_URL_TITLE} #{kibana_discover_url}" if kibana_discover_url
          errors << "#{KIBANA_DASHBOARD_URL_TITLE} #{kibana_dashboard_url}" if kibana_dashboard_url

          errors.join("\n")
        end

        def logging_environment
          address = QA::Runtime::Scenario.attributes[:gitlab_address]
          return if address.nil?

          case address
          when STAGING_ADDRESS
            :staging
          when STAGING_REF_ADDRESS
            :staging_ref
          when PRODUCTION_ADDRESS
            :production
          when PRE_PROD_ADDRESS
            :pre
          end
        end
      end
    end
  end
end
