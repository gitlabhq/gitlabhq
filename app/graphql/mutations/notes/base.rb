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
        null: true, scopes: [:api, :ai_workflows],
        description: 'Note after mutation.'

      field :quick_actions_status,
        Types::Notes::QuickActionsStatusType,
        null: true,
        description: 'Status of quick actions after mutation.',
        skip_type_authorization: [:read_note]

      private

      def load_note(id)
        note = Gitlab::Graphql::Lazy.force(GitlabSchema.find_by_gid(id))
        # A missing record is a not-found error, so raise GraphQL::ExecutionError to match
        # the old `loads:` behaviour. Authorization failures use raise_resource_not_available_error!
        # instead, so we don't leak that the record exists.
        raise GraphQL::ExecutionError, "No object found for `id: #{id.to_s.inspect}`" unless note

        raise_resource_not_available_error! unless Ability.allowed?(current_user, :read_note, note)

        note
      end
    end
  end
end
