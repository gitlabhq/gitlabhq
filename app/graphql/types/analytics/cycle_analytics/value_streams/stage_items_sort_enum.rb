# frozen_string_literal: true

module Types
  module Analytics
    module CycleAnalytics
      module ValueStreams
        class StageItemsSortEnum < BaseEnum
          graphql_name 'ValueStreamStageItemSort'
          description 'Sorting values available to value stream stage items'

          value 'DURATION_ASC', 'Duration by ascending order.', value: { sort: :duration, direction: :asc }
          value 'DURATION_DESC', 'Duration by ascending order.', value: { sort: :duration, direction: :desc }
          value 'END_EVENT_ASC', 'Stage end event time by ascending order.',
            value: { sort: :end_event, direction: :asc }
          value 'END_EVENT_DESC', 'Stage end event time by descending order.',
            value: { sort: :end_event, direction: :desc }
        end
      end
    end
  end
end
