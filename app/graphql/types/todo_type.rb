# frozen_string_literal: true

module Types
  class TodoType < BaseObject
    graphql_name 'Todo'
    description 'Representing a todo entry'

    present_using TodoPresenter

    authorize :read_todo

    field :id, GraphQL::ID_TYPE,
          description: 'ID of the todo',
          null: false

    field :project, Types::ProjectType,
          description: 'The project this todo is associated with',
          null: true,
          authorize: :read_project

    field :group, Types::GroupType,
          description: 'Group this todo is associated with',
          null: true,
          authorize: :read_group

    field :author, Types::UserType,
          description: 'The author of this todo',
          null: false

    field :action, Types::TodoActionEnum,
          description: 'Action of the todo',
          null: false

    field :target_type, Types::TodoTargetEnum,
          description: 'Target type of the todo',
          null: false

    field :body, GraphQL::STRING_TYPE,
          description: 'Body of the todo',
          null: false,
          calls_gitaly: true # TODO This is only true when `target_type` is `Commit`. See https://gitlab.com/gitlab-org/gitlab/issues/34757#note_234752665

    field :state, Types::TodoStateEnum,
          description: 'State of the todo',
          null: false

    field :created_at, Types::TimeType,
          description: 'Timestamp this todo was created',
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
