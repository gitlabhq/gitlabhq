# frozen_string_literal: true

module Mutations
  module Users
    module SavedReplies
      class Create < ::Mutations::SavedReplies::Create
        graphql_name 'SavedReplyCreate'

        field :saved_reply, ::Types::Users::SavedReplyType,
          null: true,
          description: 'Saved reply after mutation.'

        def resolve(name:, content:)
          result = ::SavedReplies::CreateService.new(object: current_user, name: name, content: content).execute
          present_result(result)
        end
      end
    end
  end
end
