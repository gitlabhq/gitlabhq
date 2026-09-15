# frozen_string_literal: true

module Mutations
  module Users
    module SavedReplies
      class Destroy < ::Mutations::SavedReplies::Destroy
        graphql_name 'SavedReplyDestroy'

        authorize_granular_token permissions: :delete_saved_reply,
          boundary: :user,
          boundary_type: :user

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
