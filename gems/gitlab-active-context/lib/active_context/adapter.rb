# frozen_string_literal: true

module ActiveContext
  module Adapter
    class << self
      def current
        @current ||= load_adapter
      end

      private

      def load_adapter
        return nil unless ActiveContext::Config.enabled?

        connection = ActiveContext::Config.connection_model&.active
        return nil unless connection

        adapter_klass = connection.adapter_class&.safe_constantize
        return nil unless adapter_klass

        options = connection.options
        adapter_klass.new(connection, options: options)
      end
    end
  end
end
