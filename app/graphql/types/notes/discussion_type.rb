# frozen_string_literal: true

module Types
  module Notes
    class DiscussionType < BaseObject
      graphql_name 'Discussion'

      authorize :read_note

      field :id, GraphQL::ID_TYPE, null: false,
            description: "ID of this discussion"
      field :reply_id, GraphQL::ID_TYPE, null: false,
            description: 'ID used to reply to this discussion'
      field :created_at, Types::TimeType, null: false,
            description: "Timestamp of the discussion's creation"
      field :notes, Types::Notes::NoteType.connection_type, null: false,
            description: 'All notes in the discussion'

      # The gem we use to generate Global IDs is hard-coded to work with
      # `id` properties. To generate a GID for the `reply_id` property,
      # we must use the ::Gitlab::GlobalId module.
      def reply_id
        ::Gitlab::GlobalId.build(object, id: object.reply_id)
      end
    end
  end
end
