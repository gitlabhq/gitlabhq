# frozen_string_literal: true

module Mutations
  module SavedReplies
    class Create < Base
      graphql_name 'SavedReplyCreate'

      authorize :create_saved_replies

      argument :name, GraphQL::Types::String,
               required: true,
               description: copy_field_description(Types::SavedReplyType, :name)

      argument :content, GraphQL::Types::String,
               required: true,
               description: copy_field_description(Types::SavedReplyType, :content)

      def resolve(name:, content:)
        raise Gitlab::Graphql::Errors::ResourceNotAvailable, 'Feature disabled' unless feature_enabled?

        result = ::Users::SavedReplies::CreateService.new(current_user: current_user, name: name, content: content).execute
        present_result(result)
      end
    end
  end
end
