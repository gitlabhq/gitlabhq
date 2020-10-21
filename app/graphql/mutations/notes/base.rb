# frozen_string_literal: true

module Mutations
  module Notes
    class Base < BaseMutation
      field :note,
            Types::Notes::NoteType,
            null: true,
            description: 'The note after mutation'

      private

      def find_object(id:)
        # TODO: remove explicit coercion once compatibility layer has been removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = ::Types::GlobalIDType[::Note].coerce_isolated_input(id)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
