# frozen_string_literal: true

module Resolvers
  module Analytics
    module CycleAnalytics
      class BaseCountResolver < BaseResolver
        type Types::Analytics::CycleAnalytics::MetricType, null: true

        argument :from, Types::TimeType,
          required: true,
          description: 'Timestamp marking the start date and time.'

        argument :to, Types::TimeType,
          required: true,
          description: 'Timestamp marking the end date and time.'

        def ready?(**args)
          start_date = args[:from]
          end_date = args[:to]

          if start_date >= end_date
            raise Gitlab::Graphql::Errors::ArgumentError,
              '`from` argument must be before `to` argument'
          end

          max_days = Gitlab::Analytics::CycleAnalytics::RequestParams::MAX_RANGE_DAYS

          if (end_date.beginning_of_day - start_date.beginning_of_day) > max_days
            raise Gitlab::Graphql::Errors::ArgumentError,
              "Max of #{max_days.inspect} timespan is allowed"
          end

          super
        end

        # :project level: no customization, returning the original resolver
        # :group level: add the project_ids argument
        def self.[](context = :project)
          case context
          when :project
            self
          when :group
            Class.new(self) do
              argument :project_ids, [GraphQL::Types::ID],
                required: false,
                description: 'Project IDs within the group hierarchy.'

              define_method :finder_params do
                { group_id: object.id, include_subgroups: true }
              end
            end
          end
        end
      end
    end
  end
end
