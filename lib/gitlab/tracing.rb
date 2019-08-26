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

      # Avoid using `format` since it can throw TypeErrors
      # which we want to avoid on unsanitised env var input
      tracing_url_template.to_s
        .gsub(/\{\{\s*correlation_id\s*\}\}/, Labkit::Correlation::CorrelationId.current_id.to_s)
        .gsub(/\{\{\s*service\s*\}\}/, Gitlab.process_name)
    end
  end
end
