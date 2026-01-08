# frozen_string_literal: true

module ActiveContext
  module Adapter
    class << self
      def current
        @current ||= load_adapter
      end

      def reset
        @current = nil
      end

      def for_connection(connection)
        return nil unless connection
        return nil unless ActiveContext::Config.enabled?

        adapter_klass = connection.adapter_class&.safe_constantize
        return nil unless adapter_klass

        options = connection.options
        adapter_klass.new(connection, options: options)
      end

      private

      def load_adapter
        return nil unless ActiveContext::Config.enabled?

        connection = ActiveContext::Config.connection_model&.active
        return nil unless connection

        for_connection(connection)
      end
    end
  end
end
