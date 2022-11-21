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
      SENTRY_ENVIRONMENTS = {
        staging: 'https://sentry.gitlab.net/gitlab/staginggitlabcom/?environment=gstg',
        staging_ref: 'https://sentry.gitlab.net/gitlab/staging-ref/?environment=all',
        pre: 'https://sentry.gitlab.net/gitlab/pregitlabcom/?environment=all',
        production: 'https://sentry.gitlab.net/gitlab/gitlabcom/?environment=gprd'
      }.freeze
      KIBANA_ENVIRONMENTS = {
        staging: 'https://nonprod-log.gitlab.net/',
        canary: 'https://log.gprd.gitlab.net/',
        production: 'https://log.gprd.gitlab.net/'
      }.freeze

      def self.failure_metadata(correlation_id)
        return if correlation_id.blank?

        sentry_base_url = get_sentry_base_url
        kibana_base_url = get_kibana_base_url

        errors = ["Correlation Id: #{correlation_id}"]
        errors << "Sentry Url: #{get_sentry_url(sentry_base_url, correlation_id)}" if sentry_base_url
        errors << "Kibana Url: #{get_kibana_url(kibana_base_url, correlation_id)}" if kibana_base_url

        errors.join("\n")
      end

      def self.get_sentry_base_url
        return unless logging_environment?

        SENTRY_ENVIRONMENTS[logging_environment]
      end

      def self.get_sentry_url(base_url, correlation_id)
        "#{base_url}&query=correlation_id%3A%22#{correlation_id}%22"
      end

      def self.get_kibana_base_url
        return unless logging_environment?

        KIBANA_ENVIRONMENTS[logging_environment]
      end

      def self.get_kibana_url(base_url, correlation_id)
        "#{base_url}app/discover#/?_a=%28query%3A%28language%3Akuery%2Cquery%3A" \
        "%27json.correlation_id%20%3A%20#{correlation_id}%27%29%29" \
        "&_g=%28time%3A%28from%3A%27#{start_time}%27%2Cto%3A%27#{end_time}%27%29%29"
      end

      def self.logging_environment
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

      def self.logging_environment?
        !logging_environment.nil?
      end

      def self.start_time
        (Time.now.utc - 24.hours).iso8601(3)
      end

      def self.end_time
        Time.now.utc.iso8601(3)
      end
    end
  end
end
