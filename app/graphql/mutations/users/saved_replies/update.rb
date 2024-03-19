# frozen_string_literal: true

module Mutations
  module Users
    module SavedReplies
      class Update < ::Mutations::SavedReplies::Update
        graphql_name 'SavedReplyUpdate'

        field :saved_reply, ::Types::Users::SavedReplyType,
          null: true,
          description: 'Saved reply after mutation.'

        argument :id, Types::GlobalIDType[::Users::SavedReply],
          required: true,
          description: copy_field_description(::Types::Users::SavedReplyType, :id)
      end
    end
  end
end
