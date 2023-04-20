# frozen_string_literal: true

module Resolvers
  module Notes
    class SyntheticNoteResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :read_note

      type Types::Notes::NoteType, null: true

      argument :sha, GraphQL::Types::String,
        required: true,
        description: 'Global ID of the note.'

      argument :noteable_id, ::Types::GlobalIDType[::Noteable],
        required: true,
        description: 'Global ID of the resource to search synthetic note on.'

      def resolve(noteable_id:, sha:)
        noteable = authorized_find!(id: noteable_id)

        synthetic_notes = ResourceEvents::MergeIntoNotesService.new(
          noteable, current_user, paginated_notes: nil
        ).execute

        synthetic_notes.find { |note| note.discussion_id == sha }
      end
    end
  end
end
