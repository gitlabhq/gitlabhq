# frozen_string_literal: true

module API
  module Hooks
    # rubocop: disable API/Base -- re-usable module
    class Events < ::Grape::API
      include PaginationParams

      desc 'Get events for a given hook id' do
        detail 'List web hook logs by hook id'
        success code: 200
        failure [
          { code: 400, message: 'Bad request' },
          { code: 404, message: 'Not found' },
          { code: 403, message: 'Forbidden' }
        ]
      end
      params do
        optional :status,
          type: Array[String],
          coerce_with: Validations::Types::CommaSeparatedToArray.coerce,
          values: Rack::Utils::HTTP_STATUS_CODES.keys.map(&:to_s) + %w[successful client_failure server_failure]
        optional :per_page, type: Integer, default: 20,
          desc: 'Number of items per page', documentation: { example: 20 },
          values: 1..20
        use :pagination
      end
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
