# frozen_string_literal: true

module SavedReplies
  class CreateService < BaseService
    def initialize(object:, name:, content:)
      @object = object
      @name = name
      @content = content
    end

    def execute
      unless object.try(:supports_saved_replies?)
        return error(_('You have insufficient permissions to create a saved reply'))
      end

      saved_reply = saved_replies.build(name: name, content: content)

      if saved_reply.save
        success(saved_reply: saved_reply)
      else
        error(saved_reply.errors.full_messages)
      end
    end

    private

    attr_reader :object, :name, :content

    delegate :saved_replies, to: :object
  end
end
