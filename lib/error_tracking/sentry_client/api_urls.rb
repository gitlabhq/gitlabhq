# frozen_string_literal: true

module ErrorTracking
  class SentryClient
    class ApiUrls
      def initialize(url_base)
        @uri = URI(url_base).freeze
      end

      def issues_url
        with_path(File.join(@uri.path, '/issues/'))
      end

      def issue_url(issue_id)
        with_path("/api/0/issues/#{escape(issue_id)}/")
      end

      def projects_url
        with_path('/api/0/projects/')
      end

      def issue_latest_event_url(issue_id)
        with_path("/api/0/issues/#{escape(issue_id)}/events/latest/")
      end

      private

      def with_path(new_path)
        new_uri = @uri.dup
        # Sentry API returns 404 if there are extra slashes in the URL
        new_uri.path = new_path.squeeze('/')

        new_uri
      end

      def escape(param)
        CGI.escape(param.to_s)
      end
    end
  end
end
