# frozen_string_literal: true

module Mutations
  module Notes
    module Create
      # This is a Base class for the Note creation Mutations and is not
      # mounted as a GraphQL mutation itself.
      class Base < Mutations::Notes::Base
        authorize :create_note

        argument :noteable_id,
                  GraphQL::ID_TYPE,
                  required: true,
                  description: 'The global id of the resource to add a note to'

        argument :body,
                  GraphQL::STRING_TYPE,
                  required: true,
                  description: copy_field_description(Types::Notes::NoteType, :body)

        def resolve(args)
          noteable = authorized_find!(id: args[:noteable_id])

          check_object_is_noteable!(noteable)

          note = ::Notes::CreateService.new(
            noteable.project,
            current_user,
            create_note_params(noteable, args)
          ).execute

          {
            note: (note if note.persisted?),
            errors: errors_on_object(note)
          }
        end

        private

        def create_note_params(noteable, args)
          {
            noteable: noteable,
            note: args[:body]
          }
        end
      end
    end
  end
end
