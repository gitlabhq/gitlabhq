# frozen_string_literal: true

module Resolvers
  module Noteable
    class NotesResolver < BaseResolver
      include LooksAhead

      type Types::Notes::NoteType.connection_type, null: false

      def resolve_with_lookahead(*)
        apply_lookahead(object.notes.fresh)
      end

      def preloads
        {
          award_emoji: [:award_emoji]
        }
      end
    end
  end
end
