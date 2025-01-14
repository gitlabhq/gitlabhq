# frozen_string_literal: true

module ActiveContext
  module Adapter
    class << self
      def current
        @current ||= load_adapter
      end

      private

      def load_adapter
        config = ActiveContext::Config.current
        return nil unless config.enabled

        name, hash = config.databases.first
        return nil unless name

        adapter = hash.fetch(:adapter)
        return nil unless adapter

        adapter_klass = adapter.safe_constantize
        return nil unless adapter_klass

        options = hash.fetch(:options)

        adapter_klass.new(options)
      end
    end
  end
end
