# frozen_string_literal: true

module Sentry
  class Client
    Error = Class.new(StandardError)
    MissingKeysError = Class.new(StandardError)
    ResponseInvalidSizeError = Class.new(StandardError)
    BadRequestError = Class.new(StandardError)

    SENTRY_API_SORT_VALUE_MAP = {
      # <accepted_by_client> => <accepted_by_sentry_api>
      'frequency' => 'freq',
      'first_seen' => 'new',
      'last_seen' => nil
    }.freeze

    attr_accessor :url, :token

    def initialize(api_url, token)
      @url = api_url
      @token = token
    end

    def issue_details(issue_id:)
      issue = get_issue(issue_id: issue_id)

      map_to_detailed_error(issue)
    end

    def issue_latest_event(issue_id:)
      latest_event = get_issue_latest_event(issue_id: issue_id)

      map_to_event(latest_event)
    end

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

    def list_projects
      projects = get_projects

      handle_mapping_exceptions do
        map_to_projects(projects)
      end
    end

    private

    def validate_size(issues)
      return if Gitlab::Utils::DeepSize.new(issues).valid?

      raise ResponseInvalidSizeError, "Sentry API response is too big. Limit is #{Gitlab::Utils::DeepSize.human_default_max_size}."
    end

    def handle_mapping_exceptions(&block)
      yield
    rescue KeyError => e
      Gitlab::Sentry.track_acceptable_exception(e)
      raise MissingKeysError, "Sentry API response is missing keys. #{e.message}"
    end

    def request_params
      {
        headers: {
          'Authorization' => "Bearer #{@token}"
        },
        follow_redirects: false
      }
    end

    def http_get(url, params = {})
      response = handle_request_exceptions do
        Gitlab::HTTP.get(url, **request_params.merge(params))
      end
      handle_response(response)
    end

    def get_issues(**keyword_args)
      response = http_get(
        issues_api_url,
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

    def get_issue(issue_id:)
      http_get(issue_api_url(issue_id))[:body]
    end

    def get_issue_latest_event(issue_id:)
      http_get(issue_latest_event_api_url(issue_id))[:body]
    end

    def get_projects
      http_get(projects_api_url)[:body]
    end

    def handle_request_exceptions
      yield
    rescue Gitlab::HTTP::Error => e
      Gitlab::Sentry.track_acceptable_exception(e)
      raise_error 'Error when connecting to Sentry'
    rescue Net::OpenTimeout
      raise_error 'Connection to Sentry timed out'
    rescue SocketError
      raise_error 'Received SocketError when trying to connect to Sentry'
    rescue OpenSSL::SSL::SSLError
      raise_error 'Sentry returned invalid SSL data'
    rescue Errno::ECONNREFUSED
      raise_error 'Connection refused'
    rescue => e
      Gitlab::Sentry.track_acceptable_exception(e)
      raise_error "Sentry request failed due to #{e.class}"
    end

    def handle_response(response)
      unless response.code == 200
        raise_error "Sentry response status code: #{response.code}"
      end

      { body: response.parsed_response, headers: response.headers }
    end

    def raise_error(message)
      raise Client::Error, message
    end

    def projects_api_url
      projects_url = URI(@url)
      projects_url.path = '/api/0/projects/'

      projects_url
    end

    def issue_api_url(issue_id)
      issue_url = URI(@url)
      issue_url.path = "/api/0/issues/#{issue_id}/"

      issue_url
    end

    def issue_latest_event_api_url(issue_id)
      latest_event_url = URI(@url)
      latest_event_url.path = "/api/0/issues/#{issue_id}/events/latest/"

      latest_event_url
    end

    def issues_api_url
      issues_url = URI(@url + '/issues/')
      issues_url.path.squeeze!('/')

      issues_url
    end

    def map_to_errors(issues)
      issues.map(&method(:map_to_error))
    end

    def map_to_projects(projects)
      projects.map(&method(:map_to_project))
    end

    def issue_url(id)
      issues_url = @url + "/issues/#{id}"

      parse_sentry_url(issues_url)
    end

    def project_url
      parse_sentry_url(@url)
    end

    def parse_sentry_url(api_url)
      url = ErrorTracking::ProjectErrorTrackingSetting.extract_sentry_external_url(api_url)

      uri = URI(url)
      uri.path.squeeze!('/')
      # Remove trailing slash
      uri = uri.to_s.gsub(/\/\z/, '')

      uri
    end

    def map_to_event(event)
      stack_trace = parse_stack_trace(event)

      Gitlab::ErrorTracking::ErrorEvent.new(
        issue_id: event.dig('groupID'),
        date_received: event.dig('dateReceived'),
        stack_trace_entries: stack_trace
      )
    end

    def parse_stack_trace(event)
      exception_entry = event.dig('entries')&.detect { |h| h['type'] == 'exception' }
      return unless exception_entry

      exception_values = exception_entry.dig('data', 'values')
      stack_trace_entry = exception_values&.detect { |h| h['stacktrace'].present? }
      return unless stack_trace_entry

      stack_trace_entry.dig('stacktrace', 'frames')
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
        first_release_last_commit: issue.dig('firstRelease', 'lastCommit'),
        last_release_last_commit: issue.dig('lastRelease', 'lastCommit'),
        first_release_short_version: issue.dig('firstRelease', 'shortVersion'),
        last_release_short_version: issue.dig('lastRelease', 'shortVersion')
      )
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

    def map_to_project(project)
      organization = project.fetch('organization')

      Gitlab::ErrorTracking::Project.new(
        id: project.fetch('id', nil),
        name: project.fetch('name'),
        slug: project.fetch('slug'),
        status: project.dig('status'),
        organization_name: organization.fetch('name'),
        organization_id: organization.fetch('id', nil),
        organization_slug: organization.fetch('slug')
      )
    end
  end
end
