# frozen_string_literal: true

module Resolvers
  module Analytics
    module CycleAnalytics
      module ValueStreams
        class StageItemsResolver < BaseResolver
          type ::Types::Analytics::CycleAnalytics::ValueStreams::StageItemsType.connection_type, null: true

          argument :sort,
            Types::Analytics::CycleAnalytics::ValueStreams::StageItemsSortEnum,
            description: 'Sort stage items by criteria.',
            required: false

          # Limit page size to the same value of RecordsFetcher to avoid slow queries
          max_page_size Gitlab::Analytics::CycleAnalytics::Aggregated::RecordsFetcher::MAX_RECORDS

          def resolve(sort: {})
            stage = object.stage
            params = object.params.merge(sort)

            # Create a new data collector with additional sort parameters
            data_collector =
              Gitlab::Analytics::CycleAnalytics::DataCollector.new(stage: stage, params: params)

            offset_pagination(data_collector.records_for_graphql)
          end
        end
      end
    end
  end
end
