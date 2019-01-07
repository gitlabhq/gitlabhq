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
  end
end
