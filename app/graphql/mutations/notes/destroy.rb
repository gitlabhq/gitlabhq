# frozen_string_literal: true

module Mutations
  module Notes
    class Destroy < Base
      graphql_name 'DestroyNote'

      authorize :admin_note

      argument :id,
                GraphQL::ID_TYPE,
                required: true,
                description: 'The global id of the note to destroy'

      def resolve(id:)
        note = authorized_find!(id: id)

        check_object_is_note!(note)

        ::Notes::DestroyService.new(note.project, current_user).execute(note)

        {
          errors: []
        }
      end
    end
  end
end
