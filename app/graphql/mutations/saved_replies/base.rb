# frozen_string_literal: true

module Mutations
  module SavedReplies
    class Base < BaseMutation
      private

      def present_result(result)
        if result[:status] == :success
          {
            saved_reply: result[:saved_reply],
            errors: []
          }
        else
          {
            saved_reply: nil,
            errors: result[:message]
          }
        end
      end
    end
  end
end
