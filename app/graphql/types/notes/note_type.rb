# frozen_string_literal: true

module Types
  module Notes
    class NoteType < BaseObject
      graphql_name 'Note'

      authorize :read_note

      expose_permissions Types::PermissionTypes::Note

      implements(Types::ResolvableInterface)

      field :id, GraphQL::ID_TYPE, null: false,
            description: 'ID of the note'

      field :project, Types::ProjectType,
            null: true,
            description: 'Project associated with the note',
            resolve: -> (note, args, context) { Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, note.project_id).find }

      field :author, Types::UserType,
            null: false,
            description: 'User who wrote this note',
            resolve: -> (note, args, context) { Gitlab::Graphql::Loaders::BatchModelLoader.new(User, note.author_id).find }

      field :system, GraphQL::BOOLEAN_TYPE,
            null: false,
            description: 'Indicates whether this note was created by the system or by a user'

      field :body, GraphQL::STRING_TYPE,
            null: false,
            method: :note,
            description: 'Content of the note'

      markdown_field :body_html, null: true, method: :note

      field :created_at, Types::TimeType, null: false,
            description: 'Timestamp of the note creation'
      field :updated_at, Types::TimeType, null: false,
            description: "Timestamp of the note's last activity"
      field :discussion, Types::Notes::DiscussionType, null: true,
            description: 'The discussion this note is a part of'
      field :position, Types::Notes::DiffPositionType, null: true,
            description: 'The position of this note on a diff'
      field :confidential, GraphQL::BOOLEAN_TYPE, null: true,
            description: 'Indicates if this note is confidential',
            method: :confidential?
    end
  end
end
