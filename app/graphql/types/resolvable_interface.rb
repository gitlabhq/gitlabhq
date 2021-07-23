# frozen_string_literal: true

module Types
  # This Interface contains fields that are shared between objects that include either
  # the `ResolvableNote` or `ResolvableDiscussion` modules.
  module ResolvableInterface
    include Types::BaseInterface

    field :resolved_by, Types::UserType,
          null: true,
          description: 'User who resolved the object.'

    def resolved_by
      return unless object.resolved_by_id

      Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.resolved_by_id).find
    end

    field :resolved, GraphQL::Types::Boolean, null: false,
          description: 'Indicates if the object is resolved.',
          method: :resolved?
    field :resolvable, GraphQL::Types::Boolean, null: false,
          description: 'Indicates if the object can be resolved.',
          method: :resolvable?
    field :resolved_at, Types::TimeType, null: true,
          description: 'Timestamp of when the object was resolved.'
  end
end
