# frozen_string_literal: true

module Mutations
  module Notes
    # This mutation differs from the update note mutations as it checks the
    # `reposition_note` permission, and doesn't allow updating a note's `body`.
    class RepositionImageDiffNote < Mutations::Notes::Base
      graphql_name 'RepositionImageDiffNote'

      description 'Repositions a DiffNote on an image (a `Note` where the `position.positionType` is `"image"`)'

      authorize :reposition_note

      argument :id,
        Types::GlobalIDType[DiffNote],
        loads: Types::Notes::NoteType,
        as: :note,
        required: true,
        description: 'Global ID of the DiffNote to update.'

      argument :position,
        Types::Notes::UpdateDiffImagePositionInputType,
        required: true,
        description: copy_field_description(Types::Notes::NoteType, :position)

      def resolve(note:, position:)
        authorize!(note)

        position = position.to_h.compact
        pre_update_checks!(note, position)

        updated_note = ::Notes::UpdateService.new(
          note.project,
          current_user,
          note_params(note.position, position)
        ).execute(note)

        {
          note: updated_note.reset,
          errors: errors_on_object(updated_note)
        }
      end

      private

      # An ImageDiffNote does not exist as a class itself, but is instead
      # just a `DiffNote` with a particular kind of `Gitlab::Diff::Position`.
      # In addition to accepting a `DiffNote` Global ID we also need to
      # perform this check.
      def pre_update_checks!(note, _position)
        unless note.position&.on_image?
          raise Gitlab::Graphql::Errors::ResourceNotAvailable,
            'Resource is not an ImageDiffNote'
        end
      end

      def note_params(old_position, new_position)
        position = old_position.to_h.merge(new_position)

        {
          position: Gitlab::Diff::Position.new(position)
        }
      end
    end
  end
end
