# frozen_string_literal: true

module Users
  module SavedReplies
    class UpdateService
      def initialize(saved_reply:, name:, content:)
        @saved_reply = saved_reply
        @name = name
        @content = content
      end

      def execute
        if saved_reply.update(name: name, content: content)
          ServiceResponse.success(payload: { saved_reply: saved_reply.reset })
        else
          ServiceResponse.error(message: saved_reply.errors.full_messages)
        end
      end

      private

      attr_reader :saved_reply, :name, :content
    end
  end
end
