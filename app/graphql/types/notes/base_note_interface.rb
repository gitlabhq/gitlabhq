# frozen_string_literal: true

module Types
  module Notes
    module BaseNoteInterface
      include Types::BaseInterface

      implements Types::ResolvableInterface

      # Mirrors the awardable allowlist in `API::AwardEmoji`. Snippet reactions, and any other
      # noteable, need separate approval before `ai_workflows` tokens can read them.
      AI_WORKFLOWS_NOTEABLE_TYPES = %w[Issue MergeRequest Epic].freeze

      field :author, Types::UserType,
        null: true,
        scopes: [:api, :read_api, :ai_workflows],
        description: 'User who wrote the note.'

      field :award_emoji, Types::AwardEmojis::AwardEmojiType.connection_type,
        null: true,
        scopes: [:api, :read_api, :ai_workflows],
        description: 'List of emoji reactions associated with the note.'

      field :body, GraphQL::Types::String,
        null: false,
        scopes: [:api, :read_api, :ai_workflows],
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
        scopes: [:api, :read_api, :ai_workflows],
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

      def award_emoji
        return unless award_emoji_readable?

        object.award_emoji
      end

      def url
        # compute note url if noteable_url is not already precomputed
        return ::Gitlab::UrlBuilder.build(object) unless context[:noteable_url]

        context[:noteable_url] + "#note_#{object.id}"
      end

      private

      # Any noteable outside the allowlist stays fail-closed for `ai_workflows` tokens.
      def award_emoji_readable?
        return true if AI_WORKFLOWS_NOTEABLE_TYPES.include?(object.noteable_type)

        scope_validator = context[:scope_validator]
        scope_validator.nil? || scope_validator.valid_for?(%i[api read_api])
      end
    end
  end
end
