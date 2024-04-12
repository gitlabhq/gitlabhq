# frozen_string_literal: true

module Types
  module Notes
    class NoteType < BaseObject
      graphql_name 'Note'

      connection_type_class Types::CountableConnectionType

      authorize :read_note

      expose_permissions Types::PermissionTypes::Note

      implements Types::ResolvableInterface

      field :max_access_level_of_author, GraphQL::Types::String,
        null: true,
        description: "Max access level of the note author in the project.",
        method: :human_max_access

      field :id, ::Types::GlobalIDType[::Note],
        null: false,
        description: 'ID of the note.'

      field :project, Types::ProjectType,
        null: true,
        description: 'Project associated with the note.'

      field :author, Types::UserType,
        null: true,
        description: 'User who wrote this note.'

      field :system, GraphQL::Types::Boolean,
        null: false,
        description: 'Indicates whether this note was created by the system or by a user.'
      field :system_note_icon_name,
        GraphQL::Types::String,
        null: true,
        description: 'Name of the icon corresponding to a system note.'

      field :body, GraphQL::Types::String,
        null: false,
        method: :note,
        description: 'Content of the note.'

      field :award_emoji, Types::AwardEmojis::AwardEmojiType.connection_type,
        null: true,
        description: 'List of emoji reactions associated with the note.'

      field :confidential, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates if this note is confidential.',
        method: :confidential?,
        deprecated: {
          reason: :renamed,
          replacement: 'internal',
          milestone: '15.5'
        }

      field :internal, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates if this note is internal.',
        method: :confidential?

      field :created_at, Types::TimeType,
        null: false,
        description: 'Timestamp of the note creation.'
      field :discussion, Types::Notes::DiscussionType,
        null: true,
        description: 'Discussion this note is a part of.'
      field :position, Types::Notes::DiffPositionType,
        null: true,
        description: 'Position of this note on a diff.'
      field :updated_at, Types::TimeType,
        null: false,
        description: "Timestamp of the note's last activity."
      field :url, GraphQL::Types::String,
        null: true,
        description: 'URL to view this Note in the Web UI.'

      field :last_edited_at, Types::TimeType,
        null: true,
        description: 'Timestamp when note was last edited.'
      field :last_edited_by, Types::UserType,
        null: true,
        description: 'User who last edited the note.'

      field :author_is_contributor, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the note author is a contributor.',
        method: :contributor?,
        calls_gitaly: true

      field :system_note_metadata, Types::Notes::SystemNoteMetadataType,
        null: true,
        description: 'Metadata for the given note if it is a system note.'

      markdown_field :body_html, null: true, method: :note

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

      # We now support also SyntheticNote notes as a NoteType, but SyntheticNote does not have a real note ID,
      # as SyntheticNote is generated dynamically from a ResourceEvent instance.
      def id
        return super unless object.is_a?(SyntheticNote)

        ::Gitlab::GlobalId.build(object, model_name: object.class.to_s, id: object.discussion_id)
      end
    end
  end
end
