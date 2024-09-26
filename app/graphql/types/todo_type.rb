# frozen_string_literal: true

module Types
  class TodoType < BaseObject
    graphql_name 'Todo'
    description 'Representing a to-do entry'

    connection_type_class Types::CountableConnectionType

    present_using TodoPresenter

    authorize :read_todo

    field :id, GraphQL::Types::ID,
      description: 'ID of the to-do item.',
      null: false

    field :project, Types::ProjectType,
      description: 'Project this to-do item is associated with.',
      null: true

    field :group, 'Types::GroupType',
      description: 'Group this to-do item is associated with.',
      null: true

    field :author, Types::UserType,
      description: 'Author of this to-do item.',
      null: false

    field :action, Types::TodoActionEnum,
      description: 'Action of the to-do item.',
      null: false

    field :target, Types::TodoableInterface,
      description: 'Target of the to-do item.',
      calls_gitaly: true,
      deprecated: { reason: 'Use `target_entity` field', milestone: '17.4' },
      null: false

    field :target_entity, Types::TodoableInterface,
      description: 'Target of the to-do item',
      calls_gitaly: true,
      null: true

    field :target_type, Types::TodoTargetEnum,
      description: 'Target type of the to-do item.',
      null: false

    field :target_url, GraphQL::Types::String, # rubocop:disable GraphQL/ExtractType -- Target already exists
      description: 'URL of the to-do item target.',
      null: true

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

    field :note, Types::Notes::NoteType,
      description: 'Note which created this to-do item.',
      null: true

    field :member_access_type, GraphQL::Types::String,
      description: 'Access type of access request to-do items.',
      null: true

    field :snoozed_until, Types::TimeType,
      description: 'The time until when the todo is snoozed.',
      null: true

    def project
      Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, object.project_id).find
    end

    def group
      Gitlab::Graphql::Loaders::BatchModelLoader.new(Group, object.group_id).find
    end

    def author
      Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.author_id).find
    end

    def target
      target_entity
    end

    def target_entity
      if object.for_commit?
        Gitlab::Graphql::Loaders::BatchCommitLoader.new(
          container_class: Project,
          container_id: object.project_id,
          oid: object.commit_id
        ).find
      else
        Gitlab::Graphql::Loaders::BatchModelLoader.new(target_type_class, object.target_id).find
      end
    end

    private

    def target_type_class
      klass = object.target_type.safe_constantize
      raise "Invalid target type \"#{object.target_type}\"" unless klass < Todoable

      klass
    end
  end
end

Types::TodoType.prepend_mod
