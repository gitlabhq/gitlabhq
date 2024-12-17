# frozen_string_literal: true

module Gitlab
  module EndpointAttributes
    class Config
      RequestUrgency = Struct.new(:name, :duration)
      REQUEST_URGENCIES = [
        RequestUrgency.new(:high, 0.25),
        RequestUrgency.new(:medium, 0.5),
        RequestUrgency.new(:default, 1),
        RequestUrgency.new(:low, 5)
      ].index_by(&:name).freeze
      SUPPORTED_ATTRIBUTES = %i[feature_category urgency].freeze

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
          raise ArgumentError, "Attributes already defined: #{conflicted.join(', ')}" if conflicted.present?

          @default_attributes.merge!(attributes)
        else
          set_attributes_for_actions(actions, attributes)
        end

        nil
      end

      def attribute_for_action(action, attribute_name)
        value = @action_attributes.dig(action.to_s, attribute_name) || @default_attributes[attribute_name]
        # Translate urgency to a representative struct
        value = REQUEST_URGENCIES[value] if attribute_name == :urgency
        value
      end

      private

      def sanitize_attributes!(attributes)
        unsupported_attributes = (attributes.keys - SUPPORTED_ATTRIBUTES).present?
        raise ArgumentError, "Attributes not supported: #{unsupported_attributes.join(', ')}" if unsupported_attributes

        if attributes[:urgency].present? && !REQUEST_URGENCIES.key?(attributes[:urgency])
          raise ArgumentError, "Urgency not supported: #{attributes[:urgency]}"
        end
      end

      def set_attributes_for_actions(actions, attributes)
        conflicted = conflicted_attributes(attributes, @default_attributes)
        if conflicted.present?
          raise ArgumentError, "#{conflicted.join(', ')} are already defined for all actions, but re-defined for #{actions.join(', ')}"
        end

        actions.each do |action|
          action = action.to_s
          if @action_attributes[action].blank?
            @action_attributes[action] = attributes.dup
          else
            conflicted = conflicted_attributes(attributes, @action_attributes[action])
            raise ArgumentError, "Attributes re-defined for action #{action}: #{conflicted.join(', ')}" if conflicted.present?

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
