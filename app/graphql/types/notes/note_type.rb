# frozen_string_literal: true

module Types
  module Notes
    class NoteType < BaseObject
      graphql_name 'Note'

      authorize :read_note

      expose_permissions Types::PermissionTypes::Note

      implements(Types::ResolvableInterface)

      field :id, ::Types::GlobalIDType[::Note], null: false,
            description: 'ID of the note.'

      field :project, Types::ProjectType,
            null: true,
            description: 'Project associated with the note.'

      field :author, Types::UserType,
            null: false,
            description: 'User who wrote this note.'

      field :system, GraphQL::Types::Boolean,
            null: false,
            description: 'Indicates whether this note was created by the system or by a user.'
      field :system_note_icon_name, GraphQL::Types::String, null: true,
            description: 'Name of the icon corresponding to a system note.'

      field :body, GraphQL::Types::String,
            null: false,
            method: :note,
            description: 'Content of the note.'

      markdown_field :body_html, null: true, method: :note

      field :created_at, Types::TimeType, null: false,
            description: 'Timestamp of the note creation.'
      field :updated_at, Types::TimeType, null: false,
            description: "Timestamp of the note's last activity."
      field :discussion, Types::Notes::DiscussionType, null: true,
            description: 'The discussion this note is a part of.'
      field :position, Types::Notes::DiffPositionType, null: true,
            description: 'The position of this note on a diff.'
      field :confidential, GraphQL::Types::Boolean, null: true,
            description: 'Indicates if this note is confidential.',
            method: :confidential?
      field :url, GraphQL::Types::String,
            null: true,
            description: 'URL to view this Note in the Web UI.'

      def url
        ::Gitlab::UrlBuilder.build(object)
      end

      def system_note_icon_name
        SystemNoteHelper.system_note_icon_name(object) if object.system?
      end

      def project
        Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, object.project_id).find
      end

      def author
        Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.author_id).find
      end
    end
  end
end
