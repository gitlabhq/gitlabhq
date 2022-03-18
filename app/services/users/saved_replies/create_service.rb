# frozen_string_literal: true

module Users
  module SavedReplies
    class CreateService
      def initialize(current_user:, name:, content:)
        @current_user = current_user
        @name = name
        @content = content
      end

      def execute
        saved_reply = saved_replies.build(name: name, content: content)

        if saved_reply.save
          ServiceResponse.success(payload: { saved_reply: saved_reply })
        else
          ServiceResponse.error(message: saved_reply.errors.full_messages)
        end
      end

      private

      attr_reader :current_user, :name, :content

      delegate :saved_replies, to: :current_user
    end
  end
end
