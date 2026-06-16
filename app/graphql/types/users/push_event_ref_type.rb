# frozen_string_literal: true

module Types
  module Users
    # rubocop:disable Graphql/AuthorizeTypes -- Always nested under EventType, which authorizes :read_event.
    class PushEventRefType < BaseObject
      graphql_name 'PushEventRef'
      description 'Ref (branch or tag) involved in a push event.'

      field :name, GraphQL::Types::String,
        null: true,
        method: :ref,
        description: 'Name of the ref (branch or tag) that was pushed.'

      field :type, GraphQL::Types::String,
        null: false,
        method: :ref_type,
        description: 'Type of the ref. One of `branch` or `tag`.'

      field :count, GraphQL::Types::Int,
        null: true,
        method: :ref_count,
        description: 'Number of refs pushed when more than one ref was pushed at once.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
