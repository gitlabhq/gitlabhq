# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

module QA
  module Support
    module Loglinking
      # Static address variables declared for mapping environment to logging URLs
      STAGING_ADDRESS     = 'https://staging.gitlab.com'
      STAGING_REF_ADDRESS = 'https://staging-ref.gitlab.com'
      PRODUCTION_ADDRESS  = 'https://gitlab.com'
      PRE_PROD_ADDRESS    = 'https://pre.gitlab.com'
      SENTRY_BASE_URLS = {
        staging: 'https://sentry.gitlab.net/gitlab/staginggitlabcom/?environment=gstg',
        staging_ref: 'https://sentry.gitlab.net/gitlab/staging-ref/?environment=all',
        pre: 'https://sentry.gitlab.net/gitlab/pregitlabcom/?environment=all',
        production: 'https://sentry.gitlab.net/gitlab/gitlabcom/?environment=gprd'
      }.freeze
      KIBANA_BASE_URLS = {
        staging: 'https://nonprod-log.gitlab.net/',
        production: 'https://log.gprd.gitlab.net/',
        pre: 'https://nonprod-log.gitlab.net/'
      }.freeze
      KIBANA_INDICES = {
        staging: 'ed942d00-5186-11ea-ad8a-f3610a492295',
        production: '7092c4e2-4eb5-46f2-8305-a7da2edad090',
        pre: 'pubsub-rails-inf-pre'
      }.freeze

      class << self
        def failure_metadata(correlation_id)
          return if correlation_id.blank?

          errors = ["Correlation Id: #{correlation_id}"]

          env = get_logging_environment

          unless env.nil?
            sentry_base_url = get_sentry_base_url(env)
            kibana_base_url = get_kibana_base_url(env)
            kibana_index = get_kibana_index(env)

            errors << "Sentry Url: #{get_sentry_url(sentry_base_url, correlation_id)}" if sentry_base_url
            errors << "Kibana Url: #{get_kibana_url(kibana_base_url, kibana_index, correlation_id)}" if kibana_base_url
          end

          errors.join("\n")
        end

        def get_sentry_base_url(env)
          SENTRY_BASE_URLS[env]
        end

        def get_sentry_url(base_url, correlation_id)
          "#{base_url}&query=correlation_id%3A%22#{correlation_id}%22"
        end

        def get_kibana_base_url(env)
          KIBANA_BASE_URLS[env]
        end

        def get_kibana_index(env)
          KIBANA_INDICES[env]
        end

        def get_kibana_url(base_url, index, correlation_id)
          "#{base_url}app/discover#/?_a=%28index:%27#{index}%27%2Cquery%3A%28language%3Akuery%2C" \
          "query%3A%27json.correlation_id%20%3A%20#{correlation_id}%27%29%29" \
          "&_g=%28time%3A%28from%3A%27#{start_time}%27%2Cto%3A%27#{end_time}%27%29%29"
        end

        def get_logging_environment
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
          else
            nil
          end
        end

        def start_time
          (Time.now.utc - 24.hours).iso8601(3)
        end

        def end_time
          Time.now.utc.iso8601(3)
        end
      end
    end
  end
end
