# frozen_string_literal: true

module Mutations
  module Notes
    module Update
      # This is a Base class for the Note update mutations and is not
      # mounted as a GraphQL mutation itself.
      class Base < Mutations::Notes::Base
        authorize :admin_note

        argument :id,
          ::Types::GlobalIDType[::Note],
          required: true,
          description: 'Global ID of the note to update.'

        def resolve(args)
          note = authorized_find!(id: args[:id])

          pre_update_checks!(note, args)

          updated_note = ::Notes::UpdateService.new(
            note.project,
            current_user,
            note_params(note, args)
          ).execute(note)

          {
            note: updated_note.destroyed? ? nil : updated_note.reset,
            errors: updated_note.destroyed? ? [] : errors_on_object(updated_note),
            quick_actions_status: updated_note.destroyed? ? nil : updated_note.quick_actions_status&.to_h
          }
        end

        private

        def pre_update_checks!(_note, _args)
          raise NotImplementedError
        end

        def note_params(_note, args)
          { note: args[:body], confidential: args[:confidential] }.compact
        end
      end
    end
  end
end
