# frozen_string_literal: true

module Types
  class EventType < BaseObject
    graphql_name 'Event'
    description 'Representing an event'

    present_using EventPresenter

    authorize :read_event

    field :id, GraphQL::Types::ID,
          description: 'ID of the event.',
          null: false

    field :author, Types::UserType,
          description: 'Author of this event.',
          null: false

    field :action, Types::EventActionEnum,
          description: 'Action of the event.',
          null: false

    field :created_at, Types::TimeType,
          description: 'When this event was created.',
          null: false

    field :updated_at, Types::TimeType,
          description: 'When this event was updated.',
          null: false

    def author
      Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.author_id).find
    end
  end
end
