# frozen_string_literal: true

module Resolvers
  module Analytics
    module CycleAnalytics
      module ValueStreams
        class StageMetricsResolver < BaseResolver
          type ::Types::Analytics::CycleAnalytics::ValueStreams::StageMetricsType, null: true

          argument :timeframe, Types::TimeframeInputType,
            required: true,
            description: 'Aggregation timeframe. Filters the issue or the merge request creation time for FOSS ' \
              'projects, and the end event timestamp for licensed projects or groups.'

          argument :assignee_usernames, [GraphQL::Types::String],
            required: false,
            description: 'Usernames of users assigned to the issue or the merge request.'

          argument :author_username, GraphQL::Types::String,
            required: false,
            description: 'Username of the author of the issue or the merge request.'

          argument :milestone_title, GraphQL::Types::String,
            required: false,
            description: 'Milestone applied to the issue or the merge request.'

          argument :label_names, [GraphQL::Types::String],
            required: false,
            description: 'Labels applied to the issue or the merge request.'

          def resolve(**args)
            Gitlab::Analytics::CycleAnalytics::DataCollector.new(stage: object,
              params: transform_params(args, object).to_data_collector_params)
          end

          private

          def transform_params(args, _stage)
            formatted_args = args.to_hash
            timeframe = args.delete(:timeframe)
            formatted_args[:created_after] = timeframe[:start]
            formatted_args[:created_before] = timeframe[:end]

            if formatted_args[:assignee_usernames].present?
              formatted_args[:assignee_username] =
                formatted_args.delete(:assignee_usernames)
            end

            formatted_args[:label_name] = formatted_args.delete(:label_names) if formatted_args[:label_names].present?

            Gitlab::Analytics::CycleAnalytics::RequestParams.new(
              namespace: object.namespace,
              current_user: current_user,
              **formatted_args.compact
            )
          end
        end
      end
    end
  end
end

Resolvers::Analytics::CycleAnalytics::ValueStreams::StageMetricsResolver.prepend_mod
