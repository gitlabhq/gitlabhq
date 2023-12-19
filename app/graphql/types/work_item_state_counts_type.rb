# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes -- Parent node applies authorization
  class WorkItemStateCountsType < BaseObject
    graphql_name 'WorkItemStateCountsType'
    description 'Represents total number of work items for the represented states'

    field :all,
      GraphQL::Types::Int,
      null: true,
      description: 'Number of work items for the project or group.'

    field :closed,
      GraphQL::Types::Int,
      null: true,
      description: 'Number of work items with state CLOSED for the project or group.'

    field :opened,
      GraphQL::Types::Int,
      null: true,
      description: 'Number of work items with state OPENED for the project or group.'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
