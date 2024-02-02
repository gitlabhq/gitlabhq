# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    class ErrorRepository
      class OpenApiStrategy
        def initialize(project)
          @project = project

          api_url = configured_api_url

          open_api.configure do |config|
            config.scheme = api_url.scheme
            config.host = [api_url.host, api_url.port].compact.join(':')
            config.server_index = nil
            config.api_key['internalToken'] = api_key
            config.logger = Gitlab::AppLogger
          end
        end

        def report_error(
          name:, description:, actor:, platform:,
          environment:, level:, occurred_at:, payload:
        )
          raise NotImplementedError, 'Use ingestion endpoint'
        end

        def find_error(id)
          api = build_api_client
          error = api.get_error(project_id, id)

          to_sentry_detailed_error(error)
        rescue ErrorTrackingOpenAPI::ApiError => e
          log_exception(e)
          nil
        end

        def list_errors(filters:, query:, sort:, limit:, cursor:)
          opts = {
            sort: "#{sort}_desc",
            status: filters[:status],
            query: query,
            cursor: cursor,
            limit: limit
          }.compact

          api = build_api_client
          errors, _status, headers = api.list_errors_with_http_info(project_id, opts)
          pagination = pagination_from_headers(headers)

          if errors.size < limit
            # Don't show next link if amount of errors is less then requested.
            # This a workaround until the Golang backend returns link cursor
            # only if there is a next page.
            pagination.next = nil
          end

          [errors.map { to_sentry_error(_1) }, pagination]
        rescue ErrorTrackingOpenAPI::ApiError => e
          log_exception(e)
          [[], ErrorRepository::Pagination.new]
        end

        def last_event_for(id)
          event = newest_event_for(id)
          return unless event

          api = build_api_client
          error = api.get_error(project_id, id)
          return unless error

          to_sentry_error_event(event, error)
        rescue ErrorTrackingOpenAPI::ApiError => e
          log_exception(e)
          nil
        end

        def update_error(id, **attributes)
          opts = attributes.slice(:status)

          body = open_api::ErrorUpdatePayload.new(opts)

          api = build_api_client
          api.update_error(project_id, id, body)

          true
        rescue ErrorTrackingOpenAPI::ApiError => e
          log_exception(e)
          false
        end

        def dsn_url(public_key)
          config = open_api::Configuration.default

          base_url = [
            config.scheme,
            "://",
            public_key,
            '@',
            config.host,
            config.base_path
          ].join('')

          "#{base_url}/projects/#{project_id}"
        end

        private

        def event_for(id, sort:)
          opts = { sort: sort, limit: 1 }

          api = build_api_client
          api.list_events(project_id, id, opts).first
        rescue ErrorTrackingOpenAPI::ApiError => e
          log_exception(e)
          nil
        end

        def newest_event_for(id)
          event_for(id, sort: 'occurred_at_desc')
        end

        def oldest_event_for(id)
          event_for(id, sort: 'occurred_at_asc')
        end

        def to_sentry_error(error)
          Gitlab::ErrorTracking::Error.new(
            id: error.fingerprint.to_s,
            title: "#{error.name}: #{error.description}",
            message: error.description,
            culprit: error.actor,
            first_seen: error.first_seen_at,
            last_seen: error.last_seen_at,
            status: error.status,
            count: error.event_count,
            user_count: error.approximated_user_count,
            frequency: error.stats&.frequency&.dig(:'24h') || []
          )
        end

        def to_sentry_detailed_error(error)
          Gitlab::ErrorTracking::DetailedError.new(
            id: error.fingerprint.to_s,
            title: "#{error.name}: #{error.description}",
            message: error.description,
            culprit: error.actor,
            first_seen: error.first_seen_at.to_s,
            last_seen: error.last_seen_at.to_s,
            count: error.event_count,
            user_count: error.approximated_user_count,
            project_id: error.project_id,
            status: error.status,
            tags: { level: nil, logger: nil },
            external_url: external_url(error.fingerprint),
            external_base_url: external_base_url,
            integrated: true,
            first_release_version: release_from(oldest_event_for(error.fingerprint)),
            last_release_version: release_from(newest_event_for(error.fingerprint)),
            frequency: error.stats&.frequency&.dig(:'24h') || []
          )
        end

        def to_sentry_error_event(event, error)
          Gitlab::ErrorTracking::ErrorEvent.new(
            issue_id: event.fingerprint.to_s,
            date_received: error.last_seen_at,
            stack_trace_entries: build_stacktrace(event)
          )
        end

        def pagination_from_headers(headers)
          links = headers['link'].to_s.split(', ')

          pagination_hash = links.map { parse_pagination_link(_1) }.compact.to_h

          ErrorRepository::Pagination.new(pagination_hash['next'], pagination_hash['prev'])
        end

        LINK_PATTERN = %r{cursor=(?<cursor>[^&]+).*; rel="(?<direction>\w+)"}

        def parse_pagination_link(content)
          match = LINK_PATTERN.match(content)
          return unless match

          [match['direction'], CGI.unescape(match['cursor'])]
        end

        def build_stacktrace(event)
          payload = parse_json(event.payload)
          return [] unless payload

          ::ErrorTracking::StacktraceBuilder.new(payload).stacktrace
        end

        def parse_json(payload)
          Gitlab::Json.parse(payload)
        rescue JSON::ParserError
        end

        def release_from(event)
          return unless event

          payload = parse_json(event.payload)
          return unless payload

          payload['release']
        end

        def project_id
          @project.id
        end

        def open_api
          ErrorTrackingOpenAPI
        end

        # For compatibility with sentry integration
        def external_url(id)
          Gitlab::Routing.url_helpers.details_namespace_project_error_tracking_index_url(
            namespace_id: @project.namespace,
            project_id: @project,
            issue_id: id)
        end

        # For compatibility with sentry integration
        def external_base_url
          Gitlab::Routing.url_helpers.project_url(@project)
        end

        def configured_api_url
          url = Gitlab::CurrentSettings.current_application_settings.error_tracking_api_url ||
            'http://localhost:8080'

          Gitlab::HTTP_V2::UrlBlocker.validate!(
            url,
            schemes: %w[http https],
            allow_localhost: true,
            deny_all_requests_except_allowed: Gitlab::CurrentSettings.deny_all_requests_except_allowed?,
            outbound_local_requests_allowlist: Gitlab::CurrentSettings.outbound_local_requests_whitelist # rubocop:disable Naming/InclusiveLanguage -- existing setting
          )

          URI(url)
        end

        def api_key
          Gitlab::CurrentSettings.current_application_settings.error_tracking_access_token
        end

        def build_api_client
          open_api::ErrorsApi.new
        end

        def log_exception(exception)
          params = {
            http_code: exception.code,
            response_body: exception.response_body&.truncate(100)
          }

          Gitlab::AppLogger.error(Gitlab::Utils::InlineHash.merge_keys(params, prefix: 'open_api'))
        end
      end
    end
  end
end
