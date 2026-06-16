# frozen_string_literal: true

module Types
  module Users
    # rubocop:disable Graphql/AuthorizeTypes -- Always nested under EventType, which authorizes :read_event.
    class PushEventCommitType < BaseObject
      graphql_name 'PushEventCommit'
      description 'Commit details associated with a push event.'

      field :count, GraphQL::Types::Int,
        null: false,
        method: :commit_count,
        description: 'Number of commits in the push.'

      field :from, GraphQL::Types::String,
        null: true,
        method: :commit_from,
        description: 'SHA of the ref tip before the push. `null` when the ref was created.'

      field :to, GraphQL::Types::String,
        null: true,
        method: :commit_to,
        description: 'SHA of the ref tip after the push. `null` when the ref was removed.'

      field :title, GraphQL::Types::String,
        null: true,
        method: :commit_title,
        description: 'Title of the most recent commit in the push.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
