# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class GroupType < BaseObject
      graphql_name 'CiGroup'

      field :detailed_status, Types::Ci::DetailedStatusType, null: true,
        description: 'Detailed status of the group.'
      field :id, GraphQL::Types::String, null: false,
        description: 'ID for a group.'
      field :jobs, Ci::JobType.connection_type, null: true,
        description: 'Jobs in group.'
      field :name, GraphQL::Types::String, null: true,
        description: 'Name of the job group.'
      field :size, GraphQL::Types::Int, null: true,
        description: 'Size of the group.'

      def detailed_status
        object.detailed_status(context[:current_user])
      end
    end
  end
end
