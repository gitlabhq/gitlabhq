# frozen_string_literal: true

module Types
  module Notes
    class DiscussionType < BaseObject
      DiscussionID = ::Types::GlobalIDType[::Discussion]

      graphql_name 'Discussion'

      authorize :read_note

      implements(Types::ResolvableInterface)

      field :id, DiscussionID, null: false,
            description: "ID of this discussion."
      field :reply_id, DiscussionID, null: false,
            description: 'ID used to reply to this discussion.'
      field :created_at, Types::TimeType, null: false,
            description: "Timestamp of the discussion's creation."
      field :notes, Types::Notes::NoteType.connection_type, null: false,
            description: 'All notes in the discussion.'
      field :noteable, Types::NoteableType, null: true,
            description: 'Object which the discussion belongs to.'

      # DiscussionID.coerce_result is suitable here, but will always mark this
      # as being a 'Discussion'. Using `GlobalId.build` guarantees that we get
      # the correct class, and that it matches `id`.
      def reply_id
        ::Gitlab::GlobalId.build(object, id: object.reply_id)
      end

      def noteable
        noteable = object.noteable

        return unless Ability.allowed?(context[:current_user], :"read_#{noteable.to_ability_name}", noteable)

        noteable
      end
    end
  end
end
