# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module ActionShapeValidation
      # The engine reads the action message from `message` and falls back to the retired
      # `blockMessage`. It refuses to serve the policy when either key is present and not a
      # string, even when the other one holds a valid message, so both are type-checked here
      # rather than only the one the engine would read. Nothing writes `blockMessage` any
      # more, so it stays here only until the engine drops its fallback.
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/628712.
      MESSAGE_KEYS = %w[message blockMessage].freeze
      private_constant :MESSAGE_KEYS

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

        MESSAGE_KEYS.all? { |key| value[key].nil? || value[key].is_a?(String) }
      end
    end
  end
end
