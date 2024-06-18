# frozen_string_literal: true

module Types
  module Notes
    class NoteType < BaseObject
      graphql_name 'Note'

      include ActionView::Helpers::SanitizeHelper
      include MarkupHelper

      connection_type_class Types::CountableConnectionType

      authorize :read_note

      expose_permissions Types::PermissionTypes::Note

      implements Types::ResolvableInterface

      present_using NotePresenter

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
        description: 'User who wrote the note.'

      field :system, GraphQL::Types::Boolean,
        null: false,
        description: 'Indicates whether the note was created by the system or by a user.'
      field :system_note_icon_name,
        GraphQL::Types::String,
        null: true,
        description: 'Name of the icon corresponding to a system note.'

      field :body, GraphQL::Types::String,
        null: false,
        method: :note,
        description: 'Content of the note.'

      field :body_first_line_html, GraphQL::Types::String,
        null: false,
        description: 'First line of the note content.'

      field :award_emoji, Types::AwardEmojis::AwardEmojiType.connection_type,
        null: true,
        description: 'List of emoji reactions associated with the note.'

      field :imported, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the note was imported.',
        method: :imported?
      field :internal, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates if the note is internal.',
        method: :confidential?

      field :created_at, Types::TimeType,
        null: false,
        description: 'Timestamp of the note creation.'
      field :discussion, Types::Notes::DiscussionType,
        null: true,
        description: 'Discussion the note is a part of.'
      field :position, Types::Notes::DiffPositionType,
        null: true,
        description: 'Position of the note on a diff.'
      field :updated_at, Types::TimeType,
        null: false,
        description: "Timestamp of the note's last activity."
      field :url, GraphQL::Types::String,
        null: true,
        description: 'URL to view the note in the Web UI.'

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

      field :body_html, GraphQL::Types::String,
        method: :note_html,
        null: true,
        description: "GitLab Flavored Markdown rendering of the content of the note."

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

        # object is a presenter, so object.object returns the concrete note object.
        ::Gitlab::GlobalId.build(object, model_name: object.object.class.to_s, id: object.discussion_id)
      end

      def body_first_line_html
        first_line_in_markdown(object, :note, 125, project: object.project)
      end
    end
  end
end
