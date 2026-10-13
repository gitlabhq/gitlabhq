# frozen_string_literal: true

module API
  module Hooks
    # rubocop: disable API/Base -- re-usable module
    class Events < ::Grape::API
      include PaginationParams

      desc 'List all events' do
        detail 'Lists all events for a specified webhook.'
        success code: 200
        failure [
          { code: 400, message: 'Bad request' },
          { code: 404, message: 'Not found' },
          { code: 403, message: 'Forbidden' }
        ]
        tags ['hooks']
      end
      params do
        optional :status,
          type: Array[String],
          coerce_with: Validations::Types::CommaSeparatedToArray.coerce,
          values: Rack::Utils::HTTP_STATUS_CODES.keys.map(&:to_s) + %w[successful client_failure server_failure],
          desc: 'Response status code of the events, for example `200` or `500`. You can search by status category: ' \
            '`successful` (200-299), `client_failure` (400-499), and `server_failure` (500-599).'
        optional :per_page, type: Integer, default: 20,
          desc: 'Number of items to list per page.', documentation: { example: 20 },
          values: 1..20
        use :pagination
      end
      given configuration[:tier] do
        route_setting :tier, configuration[:tier]
      end
      route_setting :authorization, permissions: :read_webhook_event, boundary_type: configuration[:boundary_type]
      get "events" do
        search_params = declared_params(include_missing: false)
        hook = find_hook

        logs = WebHooks::WebHookLogsFinder.new(hook, current_user, search_params).execute
        present paginate(logs), with: Entities::WebHookLog
      end
    end
    # rubocop: enable API/Base
  end
end
