# frozen_string_literal: true

module Mutations
  module SavedReplies
    class Update < Base
      authorize :update_saved_replies

      argument :name, GraphQL::Types::String,
        required: true,
        description: copy_field_description(::Types::SavedReplyType, :name)

      argument :content, GraphQL::Types::String,
        required: true,
        description: copy_field_description(::Types::SavedReplyType, :content)

      def resolve(id:, name:, content:)
        saved_reply = authorized_find!(id: id)
        result = ::SavedReplies::UpdateService.new(saved_reply: saved_reply, name: name, content: content).execute
        present_result(result)
      end
    end
  end
end
