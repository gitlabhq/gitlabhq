# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class ConfigurationEntity < Grape::Entity
      include RequestAwareEntity

      expose :events, using: Analytics::CycleAnalytics::EventEntity
      expose :stages, using: Analytics::CycleAnalytics::StageEntity

      private

      def events
        Gitlab::Analytics::CycleAnalytics::StageEvents.selectable_events
      end
    end
  end
end
