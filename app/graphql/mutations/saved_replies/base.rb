# frozen_string_literal: true

module Mutations
  module SavedReplies
    class Base < BaseMutation
      field :saved_reply, Types::SavedReplyType,
            null: true,
            description: 'Saved reply after mutation.'

      private

      def present_result(result)
        if result.success?
          {
            saved_reply: result[:saved_reply],
            errors: []
          }
        else
          {
            saved_reply: nil,
            errors: result.message
          }
        end
      end

      def find_object(id)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
