# frozen_string_literal: true

module Sentry
  class Client
    module Issue
      BadRequestError = Class.new(StandardError)

      SENTRY_API_SORT_VALUE_MAP = {
        # <accepted_by_client> => <accepted_by_sentry_api>
        'frequency' => 'freq',
        'first_seen' => 'new',
        'last_seen' => nil
      }.freeze

      def list_issues(**keyword_args)
        response = get_issues(keyword_args)

        issues = response[:issues]
        pagination = response[:pagination]

        validate_size(issues)

        handle_mapping_exceptions do
          {
            issues: map_to_errors(issues),
            pagination: pagination
          }
        end
      end

      def issue_details(issue_id:)
        issue = get_issue(issue_id: issue_id)

        map_to_detailed_error(issue)
      end

      def update_issue(issue_id:, params:)
        http_put(api_urls.issue_url(issue_id), params)[:body]
      end

      private

      def get_issues(**keyword_args)
        response = http_get(
          api_urls.issues_url,
          query: list_issue_sentry_query(keyword_args)
        )

        {
          issues: response[:body],
          pagination: Sentry::PaginationParser.parse(response[:headers])
        }
      end

      def list_issue_sentry_query(issue_status:, limit:, sort: nil, search_term: '', cursor: nil)
        unless SENTRY_API_SORT_VALUE_MAP.key?(sort)
          raise BadRequestError, 'Invalid value for sort param'
        end

        {
          query: "is:#{issue_status} #{search_term}".strip,
          limit: limit,
          sort: SENTRY_API_SORT_VALUE_MAP[sort],
          cursor: cursor
        }.compact
      end

      def validate_size(issues)
        return if Gitlab::Utils::DeepSize.new(issues).valid?

        raise ResponseInvalidSizeError, "Sentry API response is too big. Limit is #{Gitlab::Utils::DeepSize.human_default_max_size}."
      end

      def get_issue(issue_id:)
        http_get(api_urls.issue_url(issue_id))[:body]
      end

      def parse_gitlab_issue(plugin_issues)
        return unless plugin_issues

        gitlab_plugin = plugin_issues.detect { |item| item['id'] == 'gitlab' }
        return unless gitlab_plugin

        gitlab_plugin.dig('issue', 'url')
      end

      def issue_url(id)
        parse_sentry_url("#{url}/issues/#{id}")
      end

      def project_url
        parse_sentry_url(url)
      end

      def parse_sentry_url(api_url)
        url = ErrorTracking::ProjectErrorTrackingSetting.extract_sentry_external_url(api_url)

        uri = URI(url)
        uri.path.squeeze!('/')
        # Remove trailing slash
        uri = uri.to_s.gsub(/\/\z/, '')

        uri
      end

      def map_to_errors(issues)
        issues.map(&method(:map_to_error))
      end

      def map_to_error(issue)
        Gitlab::ErrorTracking::Error.new(
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
          short_id: issue.fetch('shortId', nil),
          status: issue.fetch('status', nil),
          frequency: issue.dig('stats', '24h'),
          project_id: issue.dig('project', 'id'),
          project_name: issue.dig('project', 'name'),
          project_slug: issue.dig('project', 'slug')
        )
      end

      def map_to_detailed_error(issue)
        Gitlab::ErrorTracking::DetailedError.new({
          id: issue.fetch('id'),
          first_seen: issue.fetch('firstSeen', nil),
          last_seen: issue.fetch('lastSeen', nil),
          tags: extract_tags(issue),
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
          gitlab_issue: parse_gitlab_issue(issue.fetch('pluginIssues', nil)),
          project_id: issue.dig('project', 'id'),
          project_name: issue.dig('project', 'name'),
          project_slug: issue.dig('project', 'slug'),
          first_release_last_commit: issue.dig('firstRelease', 'lastCommit'),
          first_release_short_version: issue.dig('firstRelease', 'shortVersion'),
          first_release_version: issue.dig('firstRelease', 'version'),
          last_release_last_commit: issue.dig('lastRelease', 'lastCommit'),
          last_release_short_version: issue.dig('lastRelease', 'shortVersion')
        })
      end

      def extract_tags(issue)
        {
          level: issue.fetch('level', nil),
          logger: issue.fetch('logger', nil)
        }
      end
    end
  end
end
