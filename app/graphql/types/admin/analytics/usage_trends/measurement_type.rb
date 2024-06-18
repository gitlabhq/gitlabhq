# frozen_string_literal: true

module Types
  module Admin
    module Analytics
      module UsageTrends
        class MeasurementType < BaseObject
          graphql_name 'UsageTrendsMeasurement'
          description 'Represents a recorded measurement (object count) for the Admins'

          include Gitlab::Graphql::Authorize::AuthorizeResource

          authorize :read_usage_trends_measurement

          field :recorded_at, Types::TimeType, null: true,
            description: 'Time the measurement was recorded.'

          field :count, GraphQL::Types::Int, null: false,
            description: 'Object count.'

          field :identifier,
            Types::Admin::Analytics::UsageTrends::MeasurementIdentifierEnum,
            null: false,
            description: 'Type of objects being measured.'
        end
      end
    end
  end
end
