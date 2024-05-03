# frozen_string_literal: true

module Mutations
  module SavedReplies
    class Create < Base
      authorize :create_saved_replies

      argument :name, GraphQL::Types::String,
        required: true,
        description: copy_field_description(::Types::SavedReplyType, :name)

      argument :content, GraphQL::Types::String,
        required: true,
        description: copy_field_description(::Types::SavedReplyType, :content)
    end
  end
end
