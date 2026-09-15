# frozen_string_literal: true

module Search
  module ScopeHandlers
    module Delegation
      extend ActiveSupport::Concern

      private

      def delegate_to_handler(scope, method_name, **args)
        handler = handler_for_scope(scope).new(self)

        case method_name
        when :objects
          handler.objects(**args)
        when :formatted_count
          handler.formatted_count
        when :highlight_map
          handler.highlight_map
        else
          raise ArgumentError, "Unknown handler method: #{method_name}"
        end
      end

      def handler_for_scope(scope)
        return unless defined?(::Search::ScopeHandlers::Registry)

        ::Search::ScopeHandlers::Registry.for_scope(scope)
      end
    end
  end
end
