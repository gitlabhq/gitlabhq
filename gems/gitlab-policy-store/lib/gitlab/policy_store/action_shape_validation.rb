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
          (action['value'].nil? || action['value'].is_a?(Hash))
      end
    end
  end
end
