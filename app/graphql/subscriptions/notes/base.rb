# frozen_string_literal: true

module Subscriptions
  module Notes
    class Base < ::Subscriptions::BaseSubscription
      include Gitlab::Graphql::Laziness

      argument :noteable_id, ::Types::GlobalIDType[::Noteable],
        required: false,
        description: 'ID of the noteable.'

      def authorized?(noteable_id:)
        noteable = force(GitlabSchema.find_by_gid(noteable_id))

        # unsubscribe if user cannot read the noteable anymore for any reason, e.g. issue was set confidential,
        # in the meantime the read note permissions is checked within its corresponding returned type, i.e. NoteType
        unauthorized! unless noteable && Ability.allowed?(current_user, :"read_#{noteable.to_ability_name}", noteable)

        true
      end
    end
  end
end
