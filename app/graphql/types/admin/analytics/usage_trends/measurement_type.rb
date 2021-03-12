# frozen_string_literal: true

module Types
  module Admin
    module Analytics
      module UsageTrends
        class MeasurementType < BaseObject
          include Gitlab::Graphql::Authorize::AuthorizeResource
          graphql_name 'UsageTrendsMeasurement'
          description 'Represents a recorded measurement (object count) for the Admins'

          authorize :read_usage_trends_measurement

          field :recorded_at, Types::TimeType, null: true,
                description: 'The time the measurement was recorded.'

          field :count, GraphQL::INT_TYPE, null: false,
                description: 'Object count.'

          field :identifier, Types::Admin::Analytics::UsageTrends::MeasurementIdentifierEnum, null: false,
                description: 'The type of objects being measured.'
        end
      end
    end
  end
end
