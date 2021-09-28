# frozen_string_literal: true

module Gitlab
  module EndpointAttributes
    class Config
      Duration = Struct.new(:name, :duration)
      TARGET_DURATIONS = [
        Duration.new(:very_fast, 0.25),
        Duration.new(:fast, 0.5),
        Duration.new(:medium, 1),
        Duration.new(:slow, 5)
      ].index_by(&:name).freeze
      SUPPORTED_ATTRIBUTES = %i[feature_category target_duration].freeze

      def initialize
        @default_attributes = {}
        @action_attributes = {}
      end

      def defined_actions
        @action_attributes.keys
      end

      def set(actions, attributes)
        sanitize_attributes!(attributes)

        if actions.empty?
          conflicted = conflicted_attributes(attributes, @default_attributes)
          raise ArgumentError, "Attributes already defined: #{conflicted.join(", ")}" if conflicted.present?

          @default_attributes.merge!(attributes)
        else
          set_attributes_for_actions(actions, attributes)
        end

        nil
      end

      def attribute_for_action(action, attribute_name)
        value = @action_attributes.dig(action.to_s, attribute_name) || @default_attributes[attribute_name]
        # Translate target duration to a representative struct
        value = TARGET_DURATIONS[value] if attribute_name == :target_duration
        value
      end

      private

      def sanitize_attributes!(attributes)
        unsupported_attributes = (attributes.keys - SUPPORTED_ATTRIBUTES).present?
        raise ArgumentError, "Attributes not supported: #{unsupported_attributes.join(", ")}" if unsupported_attributes

        if attributes[:target_duration].present? && !TARGET_DURATIONS.key?(attributes[:target_duration])
          raise ArgumentError, "Target duration not supported: #{attributes[:target_duration]}"
        end
      end

      def set_attributes_for_actions(actions, attributes)
        conflicted = conflicted_attributes(attributes, @default_attributes)
        if conflicted.present?
          raise ArgumentError, "#{conflicted.join(", ")} are already defined for all actions, but re-defined for #{actions.join(", ")}"
        end

        actions.each do |action|
          action = action.to_s
          if @action_attributes[action].blank?
            @action_attributes[action] = attributes.dup
          else
            conflicted = conflicted_attributes(attributes, @action_attributes[action])
            raise ArgumentError, "Attributes re-defined for action #{action}: #{conflicted.join(", ")}" if conflicted.present?

            @action_attributes[action].merge!(attributes)
          end
        end
      end

      def conflicted_attributes(attributes, existing_attributes)
        attributes.keys.filter { |attr| existing_attributes[attr].present? && existing_attributes[attr] != attributes[attr] }
      end
    end
  end
end
