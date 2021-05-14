# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class EventEntity < Grape::Entity
      expose :name
      expose :identifier
      expose :type
      expose :can_be_start_event?, as: :can_be_start_event
      expose :allowed_end_events

      private

      def type
        object.label_based? ? 'label' : 'simple'
      end

      def can_be_start_event?
        pairing_rules.has_key?(object)
      end

      def allowed_end_events
        pairing_rules.fetch(object, []).map do |event|
          event.identifier unless stage_events.internal_events.include?(event)
        end.compact
      end

      def pairing_rules
        stage_events.pairing_rules
      end

      def stage_events
        Gitlab::Analytics::CycleAnalytics::StageEvents
      end
    end
  end
end
