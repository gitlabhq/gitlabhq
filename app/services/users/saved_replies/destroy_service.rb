# frozen_string_literal: true

module Users
  module SavedReplies
    class DestroyService
      def initialize(saved_reply:)
        @saved_reply = saved_reply
      end

      def execute
        if saved_reply.destroy
          ServiceResponse.success(payload: { saved_reply: saved_reply })
        else
          ServiceResponse.error(message: saved_reply.errors.full_messages)
        end
      end

      private

      attr_reader :saved_reply
    end
  end
end
