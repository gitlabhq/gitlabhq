# frozen_string_literal: true

module Mutations
  module SavedReplies
    class Destroy < Base
      authorize :destroy_saved_replies

      def resolve(id:)
        saved_reply = authorized_find!(id: id)
        result = ::SavedReplies::DestroyService.new(saved_reply: saved_reply).execute
        present_result(result)
      end
    end
  end
end
