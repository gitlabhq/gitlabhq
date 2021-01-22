# frozen_string_literal: true

module Types
  module Admin
    module Analytics
      module InstanceStatistics
        class MeasurementType < BaseObject
          include Gitlab::Graphql::Authorize::AuthorizeResource
          graphql_name 'InstanceStatisticsMeasurement'
          description 'Represents a recorded measurement (object count) for the Admins'

          authorize :read_instance_statistics_measurements

          field :recorded_at, Types::TimeType, null: true,
                description: 'The time the measurement was recorded.'

          field :count, GraphQL::INT_TYPE, null: false,
                description: 'Object count.'

          field :identifier, Types::Admin::Analytics::InstanceStatistics::MeasurementIdentifierEnum, null: false,
                description: 'The type of objects being measured.'
        end
      end
    end
  end
end
