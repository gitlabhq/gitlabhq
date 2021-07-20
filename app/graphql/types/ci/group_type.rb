# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class GroupType < BaseObject
      graphql_name 'CiGroup'

      field :id, GraphQL::STRING_TYPE, null: false,
            description: 'ID for a group.'
      field :name, GraphQL::STRING_TYPE, null: true,
            description: 'Name of the job group.'
      field :size, GraphQL::INT_TYPE, null: true,
            description: 'Size of the group.'
      field :jobs, Ci::JobType.connection_type, null: true,
            description: 'Jobs in group.'
      field :detailed_status, Types::Ci::DetailedStatusType, null: true,
            description: 'Detailed status of the group.'

      def detailed_status
        object.detailed_status(context[:current_user])
      end
    end
  end
end
