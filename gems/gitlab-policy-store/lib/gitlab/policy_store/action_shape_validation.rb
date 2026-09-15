# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module ActionShapeValidation
      private

      def validate_action_shapes!(attributes)
        return unless attributes.key?(:actions)

        actions = attributes[:actions]
        unless actions.is_a?(Array)
          raise PolicyStore::ValidationError, "actions must be an array of { type, value } entries"
        end

        invalid = actions.each_index.reject { |index| action_shape_valid?(actions[index]) }
        return if invalid.empty?

        raise PolicyStore::ValidationError, "actions has a malformed entry at #{invalid.join(', ')}"
      end

      def action_shape_valid?(action)
        action.is_a?(Hash) &&
          action['type'].is_a?(String) && !blank?(action['type']) &&
          valid_action_value?(action['value'])
      end

      def valid_action_value?(value)
        return true if value.nil?
        return false unless value.is_a?(Hash)

        message = value['blockMessage']
        message.nil? || message.is_a?(String)
      end
    end
  end
end
