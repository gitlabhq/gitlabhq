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
      description: 'Author of the event.',
      null: false

    field :action, Types::EventActionEnum,
      description: 'Action of the event.',
      null: false

    field :created_at, Types::TimeType,
      description: 'When the event was created.',
      null: false

    field :updated_at, Types::TimeType,
      description: 'When the event was updated.',
      null: false

    field :project, Types::ProjectType,
      description: 'Project of the event.',
      null: true

    field :target, Types::Users::EventTargetType,
      description: 'Target of the event.',
      calls_gitaly: true

    def author
      Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.author_id).find
    end

    def project
      Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, object.project_id).find
    end

    def target
      # If we don't have target info, bail
      return unless object.target_type && object.target_id

      Gitlab::Graphql::Loaders::BatchModelLoader.new(target_type_class, object.target_id).find
    end

    private

    def target_type_class
      klass = object.target_type&.safe_constantize
      klass if klass.is_a?(Class)
    end
  end
end
