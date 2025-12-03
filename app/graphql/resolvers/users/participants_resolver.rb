# frozen_string_literal: true

module Resolvers
  module Users
    class ParticipantsResolver < BaseResolver
      type Types::UserType.connection_type, null: true

      def resolve(**args)
        object.visible_participants(current_user)
      end
    end
  end
end
