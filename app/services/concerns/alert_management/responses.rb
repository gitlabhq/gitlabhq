# frozen_string_literal: true

module AlertManagement
  # Module to hold common response logic for AlertManagement services.
  module Responses
    def success(alerts)
      ServiceResponse.success(payload: { alerts: Array(alerts) })
    end

    def created
      ServiceResponse.success(http_status: :created)
    end

    def bad_request
      ServiceResponse.error(message: 'Bad Request', http_status: :bad_request)
    end

    def unauthorized
      ServiceResponse.error(message: 'Unauthorized', http_status: :unauthorized)
    end

    def unprocessable_entity
      ServiceResponse.error(message: 'Unprocessable Entity', http_status: :unprocessable_entity)
    end

    def forbidden
      ServiceResponse.error(message: 'Forbidden', http_status: :forbidden)
    end
  end
end
