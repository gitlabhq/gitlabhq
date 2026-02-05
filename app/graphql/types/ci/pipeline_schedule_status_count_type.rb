# frozen_string_literal: true

module Types
  module Ci
    # rubocop:disable Graphql/AuthorizeTypes -- Authorization is handled in the resolver
    class PipelineScheduleStatusCountType < Types::BaseObject
      graphql_name 'PipelineScheduleStatusCount'
      description 'Counts of pipeline schedules by status'

      field :active, GraphQL::Types::Int, null: false, description: 'Number of active pipeline schedules.'
      field :inactive, GraphQL::Types::Int, null: false, description: 'Number of inactive pipeline schedules.'
      field :total, GraphQL::Types::Int, null: false, description: 'Total number of pipeline schedules.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
