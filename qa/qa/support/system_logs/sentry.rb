# frozen_string_literal: true

module QA
  module Support
    module SystemLogs
      class Sentry
        BASE_URLS = {
          staging: 'https://new-sentry.gitlab.net/organizations/gitlab/issues/?environment=gstg&project=3',
          staging_ref: 'https://new-sentry.gitlab.net/organizations/gitlab/projects/staging-ref/?project=18',
          pre: 'https://new-sentry.gitlab.net/organizations/gitlab/issues/?environment=pre&project=3',
          production: 'https://new-sentry.gitlab.net/organizations/gitlab/issues/?environment=gprd&project=3'
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
