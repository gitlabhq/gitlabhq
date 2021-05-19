# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class ConfigurationEntity < Grape::Entity
      include RequestAwareEntity

      expose :events, using: Analytics::CycleAnalytics::EventEntity
      expose :stages, using: Analytics::CycleAnalytics::StageEntity

      private

      def events
        (stage_events.events - stage_events.internal_events).sort_by(&:name)
      end

      def stage_events
        Gitlab::Analytics::CycleAnalytics::StageEvents
      end
    end
  end
end
