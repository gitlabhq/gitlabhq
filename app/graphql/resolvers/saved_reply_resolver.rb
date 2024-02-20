# frozen_string_literal: true

module Resolvers
  class SavedReplyResolver < BaseResolver
    type ::Types::Users::SavedReplyType, null: true

    alias_method :target, :object

    argument :id, Types::GlobalIDType[::Users::SavedReply],
      required: true,
      description: 'ID of a saved reply.'

    def resolve(id:)
      ::Users::SavedReply.find_saved_reply(user_id: current_user.id, id: id.model_id)
    end
  end
end
