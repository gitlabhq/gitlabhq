# frozen_string_literal: true

module Mutations
  module Notes
    class Update < Base
      graphql_name 'UpdateNote'

      authorize :admin_note

      argument :id,
                GraphQL::ID_TYPE,
                required: true,
                description: 'The global id of the note to update'

      argument :body,
                GraphQL::STRING_TYPE,
                required: true,
                description: copy_field_description(Types::Notes::NoteType, :body)

      def resolve(args)
        note = authorized_find!(id: args[:id])

        check_object_is_note!(note)

        note = ::Notes::UpdateService.new(
          note.project,
          current_user,
          { note: args[:body] }
        ).execute(note)

        {
          note: note.reset,
          errors: errors_on_object(note)
        }
      end
    end
  end
end
