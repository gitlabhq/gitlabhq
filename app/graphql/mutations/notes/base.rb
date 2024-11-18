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

      field :quick_actions_status,
        Types::Notes::QuickActionsStatusType,
        null: true,
        description: 'Status of quick actions after mutation.',
        skip_type_authorization: [:read_note]
    end
  end
end
