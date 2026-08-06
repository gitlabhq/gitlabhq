# frozen_string_literal: true

module Mutations
  module Notes
    class ConvertToThread < Mutations::Notes::Base
      graphql_name 'NoteConvertToThread'
      description 'Convert a standard comment to a resolvable thread.'

      # Permissions are more lenient for converting to a thread because we do not
      # change the note body. Any user that can resolve notes can convert the note
      # to a thread.
      authorize :resolve_note
      authorize_granular_token permissions: :update_note,
        boundary_argument: :id, boundary: :resource_parent, boundary_type: :project

      argument :id,
        Types::GlobalIDType[Note],
        required: true,
        description: 'Global ID of the Note to convert.'

      def resolve(id:)
        note = load_note(id)
        authorize!(note)

        discussion = note.to_discussion

        unless discussion.can_convert_to_discussion?
          raise Gitlab::Graphql::Errors::ArgumentError, 'Note cannot be converted to a resolvable thread'
        end

        discussion = discussion.convert_to_discussion!

        if discussion.save
          { note: discussion.first_note, errors: [] }
        else
          { errors: errors_on_object(discussion.first_note) }
        end
      end
    end
  end
end
