# frozen_string_literal: true

module Resolvers
  module Noteable
    class NotesResolver < BaseResolver
      include LooksAhead

      type Types::Notes::NoteType.connection_type, null: false

      argument :filter, Types::WorkItems::NotesFilterTypeEnum,
        required: false,
        default_value: ::UserPreference::NOTES_FILTERS[:all_notes],
        description: 'Type of notes collection: ALL_NOTES, ONLY_COMMENTS, ONLY_ACTIVITY.'

      before_connection_authorization do |nodes, current_user|
        next if nodes.blank?

        # For all noteables where we use this resolver, we can assume that all notes will belong to the same project
        project = nodes.first.project

        ::Preloaders::Projects::NotesPreloader.new(project, current_user).call(nodes)
      end

      def resolve_with_lookahead(**args)
        # TODO: Implement as part of completion https://gitlab.com/gitlab-org/gitlab/-/issues/458264
        return [] if object.is_a?(AbuseReport)

        notes = NotesFinder.new(current_user, build_params(args)).execute
        apply_lookahead(notes)
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

      def build_params(args)
        params = {
          project: object.project,
          target: object
        }

        params[:notes_filter] = args[:filter] if args[:filter].present?

        params
      end
    end
  end
end
