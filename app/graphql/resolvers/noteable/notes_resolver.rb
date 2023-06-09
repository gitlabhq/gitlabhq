# frozen_string_literal: true

module Resolvers
  module Noteable
    class NotesResolver < BaseResolver
      include LooksAhead

      type Types::Notes::NoteType.connection_type, null: false

      before_connection_authorization do |nodes, current_user|
        next if nodes.blank?

        # For all noteables where we use this resolver, we can assume that all notes will belong to the same project
        project = nodes.first.project

        ::Preloaders::Projects::NotesPreloader.new(project, current_user).call(nodes)
      end

      def resolve_with_lookahead(*)
        apply_lookahead(object.notes.fresh)
      end

      private

      def unconditional_includes
        [:author, :project]
      end

      def preloads
        {
          award_emoji: [:award_emoji]
        }
      end
    end
  end
end
