# frozen_string_literal: true

module Gitlab
  module Tracing
    # Only enable tracing when the `GITLAB_TRACING` env var is configured. Note that we avoid using ApplicationSettings since
    # the same environment variable needs to be configured for Workhorse, Gitaly and any other components which
    # emit tracing. Since other components may start before Rails, and may not have access to ApplicationSettings,
    # an env var makes more sense.
    def self.enabled?
      connection_string.present?
    end

    def self.connection_string
      ENV['GITLAB_TRACING']
    end

    def self.tracing_url_template
      ENV['GITLAB_TRACING_URL']
    end

    def self.tracing_url_enabled?
      enabled? && tracing_url_template.present?
    end

    # This will provide a link into the distributed tracing for the current trace,
    # if it has been captured.
    def self.tracing_url
      return unless tracing_url_enabled?

      tracing_url_template % {
        correlation_id: Gitlab::CorrelationId.current_id.to_s,
        service: Gitlab.process_name
      }
    end
  end
end
