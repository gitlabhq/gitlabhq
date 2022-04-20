# frozen_string_literal: true
module QA
  module Support
    module Loglinking
      # Static address variables declared for mapping environment to logging URLs
      STAGING_ADDRESS     = 'https://staging.gitlab.com'
      STAGING_REF_ADDRESS = 'https://staging-ref.gitlab.com'
      PRODUCTION_ADDRESS  = 'https://gitlab.com'
      PRE_PROD_ADDRESS    = 'https://pre.gitlab.com'
      SENTRY_ENVIRONMENTS = {
        staging:        'https://sentry.gitlab.net/gitlab/staginggitlabcom/?environment=gstg',
        staging_canary: 'https://sentry.gitlab.net/gitlab/staginggitlabcom/?environment=gstg-cny',
        staging_ref:    'https://sentry.gitlab.net/gitlab/staging-ref/?environment=gstg-ref',
        pre:            'https://sentry.gitlab.net/gitlab/pregitlabcom/?environment=pre',
        canary:         'https://sentry.gitlab.net/gitlab/gitlabcom/?environment=gprd',
        production:     'https://sentry.gitlab.net/gitlab/gitlabcom/?environment=gprd-cny'
      }.freeze
      KIBANA_ENVIRONMENTS = {
        staging:        'https://nonprod-log.gitlab.net/',
        staging_canary: 'https://nonprod-log.gitlab.net/',
        canary:         'https://log.gprd.gitlab.net/',
        production:     'https://log.gprd.gitlab.net/'
      }.freeze

      def self.failure_metadata(correlation_id)
        return if correlation_id.blank?

        sentry_uri = sentry_url
        kibana_uri = kibana_url

        errors = ["Correlation Id: #{correlation_id}"]
        errors << "Sentry Url: #{sentry_uri}&query=correlation_id%3A%22#{correlation_id}%22" if sentry_uri
        errors << "Kibana Url: #{kibana_uri}app/discover#/?_a=(query:(language:kuery,query:'json.correlation_id%20:%20#{correlation_id}'))&_g=(time:(from:now-24h%2Fh,to:now))" if kibana_uri

        errors.join("\n")
      end

      def self.sentry_url
        return unless logging_environment?

        SENTRY_ENVIRONMENTS[logging_environment]
      end

      def self.kibana_url
        return unless logging_environment?

        KIBANA_ENVIRONMENTS[logging_environment]
      end

      def self.logging_environment
        address = QA::Runtime::Scenario.attributes[:gitlab_address]
        return if address.nil?

        case address
        when STAGING_ADDRESS
          canary? ? :staging_canary : :staging
        when STAGING_REF_ADDRESS
          :staging_ref
        when PRODUCTION_ADDRESS
          canary? ? :canary : :production
        when PRE_PROD_ADDRESS
          :pre
        else
          nil
        end
      end

      def self.logging_environment?
        !logging_environment.nil?
      end

      def self.cookies
        browser_cookies = Capybara.current_session.driver.browser.manage.all_cookies
        # rubocop:disable Rails/IndexBy
        browser_cookies.each_with_object({}) do |cookie, memo|
          memo[cookie[:name]] = cookie
        end
        # rubocop:enable Rails/IndexBy
      end

      def self.canary?
        cookies.dig('gitlab_canary', :value) == 'true'
      end
    end
  end
end
