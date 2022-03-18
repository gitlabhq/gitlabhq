# frozen_string_literal: true

module Mutations
  module SavedReplies
    class Update < Base
      graphql_name 'SavedReplyUpdate'

      authorize :update_saved_replies

      argument :id, Types::GlobalIDType[::Users::SavedReply],
               required: true,
               description: copy_field_description(Types::SavedReplyType, :id)

      argument :name, GraphQL::Types::String,
               required: true,
               description: copy_field_description(Types::SavedReplyType, :name)

      argument :content, GraphQL::Types::String,
               required: true,
               description: copy_field_description(Types::SavedReplyType, :content)

      def resolve(id:, name:, content:)
        raise Gitlab::Graphql::Errors::ResourceNotAvailable, 'Feature disabled' unless feature_enabled?

        saved_reply = authorized_find!(id)
        result = ::Users::SavedReplies::UpdateService.new(saved_reply: saved_reply, name: name, content: content).execute
        present_result(result)
      end
    end
  end
end
