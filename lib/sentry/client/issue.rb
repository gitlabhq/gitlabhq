# frozen_string_literal: true

module Sentry
  class Client
    module Issue
      def issue_details(issue_id:)
        issue = get_issue(issue_id: issue_id)

        map_to_detailed_error(issue)
      end

      private

      def get_issue(issue_id:)
        http_get(issue_api_url(issue_id))[:body]
      end

      def issue_api_url(issue_id)
        issue_url = URI(url)
        issue_url.path = "/api/0/issues/#{CGI.escape(issue_id.to_s)}/"

        issue_url
      end

      def parse_gitlab_issue(plugin_issues)
        return unless plugin_issues

        gitlab_plugin = plugin_issues.detect { |item| item['id'] == 'gitlab' }
        return unless gitlab_plugin

        gitlab_plugin.dig('issue', 'url')
      end

      def map_to_detailed_error(issue)
        Gitlab::ErrorTracking::DetailedError.new(
          id: issue.fetch('id'),
          first_seen: issue.fetch('firstSeen', nil),
          last_seen: issue.fetch('lastSeen', nil),
          title: issue.fetch('title', nil),
          type: issue.fetch('type', nil),
          user_count: issue.fetch('userCount', nil),
          count: issue.fetch('count', nil),
          message: issue.dig('metadata', 'value'),
          culprit: issue.fetch('culprit', nil),
          external_url: issue_url(issue.fetch('id')),
          external_base_url: project_url,
          short_id: issue.fetch('shortId', nil),
          status: issue.fetch('status', nil),
          frequency: issue.dig('stats', '24h'),
          project_id: issue.dig('project', 'id'),
          project_name: issue.dig('project', 'name'),
          project_slug: issue.dig('project', 'slug'),
          gitlab_issue: parse_gitlab_issue(issue.fetch('pluginIssues', nil)),
          first_release_last_commit: issue.dig('firstRelease', 'lastCommit'),
          last_release_last_commit: issue.dig('lastRelease', 'lastCommit'),
          first_release_short_version: issue.dig('firstRelease', 'shortVersion'),
          last_release_short_version: issue.dig('lastRelease', 'shortVersion')
        )
      end
    end
  end
end
