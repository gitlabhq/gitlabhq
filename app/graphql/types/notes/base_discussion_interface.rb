# frozen_string_literal: true

module Types
  module Notes
    module BaseDiscussionInterface
      include Types::BaseInterface

      DiscussionID = ::Types::GlobalIDType[::Discussion]

      implements Types::ResolvableInterface

      field :created_at, Types::TimeType, null: false,
        description: "Timestamp of the discussion's creation."
      field :id, DiscussionID, null: false,
        description: "ID of the discussion."
      field :reply_id, DiscussionID, null: false,
        description: 'ID used to reply to the discussion.'

      # DiscussionID.coerce_result is suitable here, but will always mark this
      # as being a 'Discussion'. Using `GlobalId.build` guarantees that we get
      # the correct class, and that it matches `id`.
      def reply_id
        ::Gitlab::GlobalId.build(object, id: object.reply_id)
      end
    end
  end
end
