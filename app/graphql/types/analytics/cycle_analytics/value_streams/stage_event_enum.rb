# frozen_string_literal: true

module Types
  module Analytics
    module CycleAnalytics
      module ValueStreams
        class StageEventEnum < BaseEnum
          graphql_name 'ValueStreamStageEvent'
          description 'Stage event identifiers'

          Gitlab::Analytics::CycleAnalytics::StageEvents.to_enum.each do |key, value|
            value(key.to_s.upcase, description: "#{key.to_s.humanize} event.", value: value)
          end
        end
      end
    end
  end
end
