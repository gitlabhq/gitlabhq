# frozen_string_literal: true

module Mutations
  module Notes
    class Base < BaseMutation
      QUICK_ACTION_ONLY_WARNING = <<~NB
        If the body of the Note contains only quick actions,
        the Note will be destroyed during an update, and no Note will be
        returned.
      NB

      field :note,
            Types::Notes::NoteType,
            null: true,
            description: 'Note after mutation.'

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
