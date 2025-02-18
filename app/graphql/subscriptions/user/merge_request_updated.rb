# frozen_string_literal: true

module Subscriptions # rubocop:disable Gitlab/BoundedContexts -- Existing module
  module User
    class MergeRequestUpdated < ::Subscriptions::BaseSubscription
      include Gitlab::Graphql::Laziness

      argument :user_id, ::Types::GlobalIDType[::User],
        required: true,
        description: 'ID of the user.'

      payload_type Types::MergeRequestType

      def authorized?(user_id:)
        user = force(GitlabSchema.find_by_gid(user_id))

        unauthorized! unless user && current_user.id == user.id

        true
      end

      def update(user_id:)
        return NO_UPDATE unless Ability.allowed?(current_user, :read_merge_request, object)

        super
      end
    end
  end
end
