# frozen_string_literal: true

module Types
  module Analytics
    module CycleAnalytics
      module ValueStreams
        # rubocop: disable Graphql/AuthorizeTypes -- # Already authorized in parent value stream type.
        class StageMetricsType < BaseObject
          graphql_name 'ValueStreamStageMetrics'

          field :average,
            ::Types::Analytics::CycleAnalytics::MetricType,
            description: 'Average duration in seconds.'

          field :count,
            ::Types::Analytics::CycleAnalytics::MetricType,
            description: 'Limited item count. The backend counts maximum 1000 items, ' \
              'for free projects, and maximum 10,000 items for licensed ' \
              'projects or licensed groups.'

          field :median,
            ::Types::Analytics::CycleAnalytics::MetricType,
            description: 'Median duration in seconds.'

          field :items,
            description: 'Items in the stage.',
            resolver: Resolvers::Analytics::CycleAnalytics::ValueStreams::StageItemsResolver,
            experiment: { milestone: '17.4' }

          def count
            {
              value: object.count,
              identifier: 'value_stream_stage_count',
              title: s_('CycleAnalytics|Item count')
            }
          end

          def average
            {
              value: object.average.seconds,
              identifier: 'value_stream_stage_average',
              title: s_('CycleAnalytics|Average duration'),
              unit: s_('CycleAnalytics|seconds')
            }
          end

          def median
            {
              value: object.median.seconds,
              identifier: 'value_stream_stage_median',
              title: s_('CycleAnalytics|Median duration'),
              unit: s_('CycleAnalytics|seconds')
            }
          end
        end
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end

Types::Analytics::CycleAnalytics::ValueStreams::StageMetricsType.prepend_mod
