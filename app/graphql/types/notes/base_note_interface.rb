# frozen_string_literal: true

module Types
  module Notes
    module BaseNoteInterface
      include Types::BaseInterface

      implements Types::ResolvableInterface

      field :author, Types::UserType,
        null: true,
        description: 'User who wrote the note.'

      field :award_emoji, Types::AwardEmojis::AwardEmojiType.connection_type,
        null: true,
        description: 'List of emoji reactions associated with the note.'

      field :body, GraphQL::Types::String,
        null: false,
        method: :note,
        description: 'Content of the note.'

      field :body_first_line_html, GraphQL::Types::String,
        method: :note_first_line_html,
        null: false,
        description: 'First line of the note content.'

      field :body_html, GraphQL::Types::String,
        method: :note_html,
        null: true,
        calls_gitaly: true,
        description: "GitLab Flavored Markdown rendering of the content of the note."

      field :created_at, Types::TimeType,
        null: false,
        description: 'Timestamp of the note creation.'

      field :last_edited_at, Types::TimeType,
        null: true,
        description: 'Timestamp when note was last edited.'

      field :last_edited_by, Types::UserType,
        null: true,
        description: 'User who last edited the note.'

      field :updated_at, Types::TimeType,
        null: false,
        description: "Timestamp of the note's last activity."

      field :url, GraphQL::Types::String,
        null: true,
        description: 'URL to view the note in the Web UI.'

      def author
        Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.author_id).find
      end

      def url
        # compute note url if noteable_url is not already precomputed
        return ::Gitlab::UrlBuilder.build(object) unless context[:noteable_url]

        context[:noteable_url] + "#note_#{object.id}"
      end
    end
  end
end
