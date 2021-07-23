# frozen_string_literal: true

module Types
  class TodoType < BaseObject
    graphql_name 'Todo'
    description 'Representing a to-do entry'

    present_using TodoPresenter

    authorize :read_todo

    field :id, GraphQL::Types::ID,
          description: 'ID of the to-do item.',
          null: false

    field :project, Types::ProjectType,
          description: 'The project this to-do item is associated with.',
          null: true,
          authorize: :read_project

    field :group, Types::GroupType,
          description: 'Group this to-do item is associated with.',
          null: true,
          authorize: :read_group

    field :author, Types::UserType,
          description: 'The author of this to-do item.',
          null: false

    field :action, Types::TodoActionEnum,
          description: 'Action of the to-do item.',
          null: false

    field :target_type, Types::TodoTargetEnum,
          description: 'Target type of the to-do item.',
          null: false

    field :body, GraphQL::Types::String,
          description: 'Body of the to-do item.',
          null: false,
          calls_gitaly: true # TODO This is only true when `target_type` is `Commit`. See https://gitlab.com/gitlab-org/gitlab/issues/34757#note_234752665

    field :state, Types::TodoStateEnum,
          description: 'State of the to-do item.',
          null: false

    field :created_at, Types::TimeType,
          description: 'Timestamp this to-do item was created.',
          null: false

    def project
      Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, object.project_id).find
    end

    def group
      Gitlab::Graphql::Loaders::BatchModelLoader.new(Group, object.group_id).find
    end

    def author
      Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.author_id).find
    end
  end
end
