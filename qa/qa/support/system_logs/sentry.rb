# frozen_string_literal: true

module QA
  module Support
    module SystemLogs
      class Sentry
        BASE_URLS = {
          staging: 'https://sentry.gitlab.net/gitlab/staginggitlabcom/?environment=gstg',
          staging_ref: 'https://sentry.gitlab.net/gitlab/staging-ref/?environment=all',
          pre: 'https://sentry.gitlab.net/gitlab/pregitlabcom/?environment=all',
          production: 'https://sentry.gitlab.net/gitlab/gitlabcom/?environment=gprd'
        }.freeze

        def initialize(env, correlation_id)
          @base_url = BASE_URLS[env]
          @correlation_id = correlation_id
        end

        def url
          return if @base_url.nil?

          "#{@base_url}&query=correlation_id%3A%22#{@correlation_id}%22"
        end
      end
    end
  end
end
