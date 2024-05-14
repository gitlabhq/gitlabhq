# frozen_string_literal: true

module SavedReplies
  class DestroyService < BaseService
    def initialize(saved_reply:)
      @saved_reply = saved_reply
    end

    def execute
      if saved_reply.destroy
        success(saved_reply: saved_reply)
      else
        error(saved_reply.errors.full_messages)
      end
    end

    private

    attr_reader :saved_reply
  end
end
