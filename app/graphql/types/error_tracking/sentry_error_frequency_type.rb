# frozen_string_literal: true

module Types
  module ErrorTracking
    # rubocop: disable Graphql/AuthorizeTypes
    class SentryErrorFrequencyType < ::Types::BaseObject
      graphql_name 'SentryErrorFrequency'

      field :time, Types::TimeType,
        null: false,
        description: "Time the error frequency stats were recorded."
      field :count, GraphQL::Types::Int,
        null: false,
        description: "Count of errors received since the previously recorded time."
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
