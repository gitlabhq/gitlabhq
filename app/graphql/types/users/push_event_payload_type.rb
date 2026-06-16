# frozen_string_literal: true

module Types
  module Users
    # rubocop:disable Graphql/AuthorizeTypes -- Always nested under EventType, which authorizes :read_event.
    class PushEventPayloadType < BaseObject
      graphql_name 'PushEventPayload'
      description 'Represents the payload of a push event.'

      field :action, GraphQL::Types::String,
        null: false,
        description: 'Action performed on the ref. One of `created`, `removed`, or `pushed`.'

      field :ref, ::Types::Users::PushEventRefType,
        null: false,
        method: :itself,
        description: 'Ref (branch or tag) involved in the push.'

      field :commit, ::Types::Users::PushEventCommitType,
        null: false,
        method: :itself,
        description: 'Commit details for the push.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
