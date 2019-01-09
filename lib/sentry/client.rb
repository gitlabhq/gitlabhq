# frozen_string_literal: true

module Sentry
  class Client
    Error = Class.new(StandardError)

    attr_accessor :url, :token

    def initialize(api_url, token)
      @url = api_url
      @token = token
    end

    def list_issues(issue_status:, limit:)
      issues = get_issues(issue_status: issue_status, limit: limit)
      map_to_errors(issues)
    end

    private

    def request_params
      {
        headers: {
          'Authorization' => "Bearer #{@token}"
        },
        follow_redirects: false
      }
    end

    def get_issues(issue_status:, limit:)
      resp = Gitlab::HTTP.get(
        issues_api_url,
        **request_params.merge(query: {
          query: "is:#{issue_status}",
          limit: limit
        })
      )

      handle_response(resp)
    end

    def handle_response(response)
      unless response.code == 200
        raise Client::Error, "Sentry response error: #{response.code}"
      end

      response.as_json
    end

    def issues_api_url
      issues_url = URI(@url + '/issues/')
      issues_url.path.squeeze!('/')

      issues_url
    end

    def map_to_errors(issues)
      issues.map do |issue|
        map_to_error(issue)
      end
    end

    def issue_url(id)
      issues_url = @url + "/issues/#{id}"
      issues_url = ErrorTracking::ProjectErrorTrackingSetting.extract_sentry_external_url(issues_url)

      uri = URI(issues_url)
      uri.path.squeeze!('/')

      uri.to_s
    end

    def map_to_error(issue)
      id = issue.fetch('id')
      project = issue.fetch('project')

      count = issue.fetch('count', nil)

      frequency = issue.dig('stats', '24h')
      message = issue.dig('metadata', 'value')

      external_url = issue_url(id)

      Gitlab::ErrorTracking::Error.new(
        id: id,
        first_seen: issue.fetch('firstSeen', nil),
        last_seen: issue.fetch('lastSeen', nil),
        title: issue.fetch('title', nil),
        type: issue.fetch('type', nil),
        user_count: issue.fetch('userCount', nil),
        count: count,
        message: message,
        culprit: issue.fetch('culprit', nil),
        external_url: external_url,
        short_id: issue.fetch('shortId', nil),
        status: issue.fetch('status', nil),
        frequency: frequency,
        project_id: project.fetch('id'),
        project_name: project.fetch('name', nil),
        project_slug: project.fetch('slug', nil)
      )
    end
  end
end
