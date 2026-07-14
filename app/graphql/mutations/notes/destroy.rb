# frozen_string_literal: true

module Mutations
  module Notes
    class Destroy < Base
      graphql_name 'DestroyNote'

      authorize :admin_note

      authorize_granular_token permissions: :delete_note,
        boundaries: [
          { boundary_argument: :id, boundary: :resource_parent, boundary_type: :project },
          { boundary_argument: :id, boundary: :resource_parent, boundary_type: :group }
        ]

      argument :id,
        ::Types::GlobalIDType[::Note],
        required: true,
        description: 'Global ID of the note to destroy.'

      def resolve(id:)
        note = authorized_find!(id: id)

        ::Notes::DestroyService.new(note.project, current_user).execute(note)

        {
          errors: []
        }
      end
    end
  end
end
