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
    end
  end
end
