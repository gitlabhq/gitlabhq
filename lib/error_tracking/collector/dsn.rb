# frozen_string_literal: true

module ErrorTracking
  module Collector
    class Dsn
      # Build a sentry compatible DSN URL for GitLab collector.
      #
      # The expected URL looks like that:
      #   https://PUBLIC_KEY@gitlab.example.com/api/v4/error_tracking/collector/PROJECT_ID
      #
      def self.build_url(public_key, project_id)
        gitlab = Settings.gitlab

        custom_port = Settings.gitlab_on_standard_port? ? nil : ":#{gitlab.port}"

        base_url = [
          gitlab.protocol,
          "://",
          public_key,
          '@',
          gitlab.host,
          custom_port,
          gitlab.relative_url_root
        ].join('')

        "#{base_url}/api/v4/error_tracking/collector/#{project_id}"
      end
    end
  end
end
