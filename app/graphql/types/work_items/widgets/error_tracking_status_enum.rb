# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class ErrorTrackingStatusEnum < BaseEnum
        graphql_name 'ErrorTrackingStatus'
        description 'Status of the error tracking service'

        value 'SUCCESS', value: :success, description: 'Successfuly fetch the stack trace.'
        value 'ERROR', value: :error, description: 'Error tracking service respond with an error.'
        value 'NOT_FOUND', value: :not_found, description: 'Sentry issue not found.'
        value 'RETRY', value: :retry, description: 'Error tracking service is not ready.'
      end
    end
  end
end
