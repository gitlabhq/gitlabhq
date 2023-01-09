# frozen_string_literal: true

module Integrations
  module Test
    class BaseService
      include BaseServiceUtility

      attr_accessor :integration, :current_user, :event

      # @param integration [Service] The external service that will be called
      # @param current_user [User] The user calling the service
      # @param event [String/nil] The event that triggered this
      def initialize(integration, current_user, event = nil)
        @integration = integration
        @current_user = current_user
        @event = event
      end

      def execute
        if event && (integration.supported_events.exclude?(event) || data.blank?)
          return error('Testing not available for this event')
        end

        integration.test(data)
      rescue ArgumentError => e
        error(e.message)
      end

      private

      def data
        raise NotImplementedError
      end
    end
  end
end
