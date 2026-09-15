# frozen_string_literal: true

module Resolvers
  module Users
    class SavedRepliesResolver < BaseResolver
      type Types::Users::SavedReplyType.connection_type, null: true

      def resolve
        return ::SavedReply.none unless Ability.allowed?(current_user, :read_user_profile, object)

        object.saved_replies.order_by_name
      end
    end
  end
end
