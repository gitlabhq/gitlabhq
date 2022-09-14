# frozen_string_literal: true

module RuboCop
  module Cop
    class SafeParams < RuboCop::Cop::Base
      MSG = 'Use `safe_params` instead of `params` in url_for.'

      METHOD_NAME_PATTERN = :url_for
      UNSAFE_PARAM = :params

      def on_send(node)
        return unless method_name(node) == METHOD_NAME_PATTERN

        add_offense(node) unless safe_params?(node)
      end

      private

      def safe_params?(node)
        node.descendants.each do |param_node|
          next unless param_node.descendants.empty?

          return false if method_name(param_node) == UNSAFE_PARAM
        end

        true
      end

      def method_name(node)
        node.children[1]
      end
    end
  end
end
