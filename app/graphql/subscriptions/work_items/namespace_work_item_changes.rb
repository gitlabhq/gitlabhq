# frozen_string_literal: true

module Subscriptions
  module WorkItems
    class NamespaceWorkItemChanges < BaseSubscription
      include Gitlab::Graphql::Laziness

      payload_type Types::WorkItems::NamespaceWorkItemChangesPayloadType

      argument :namespace_id, ::Types::GlobalIDType[::Namespace],
        required: true,
        description: 'Namespace to receive work item updates for.'

      def authorized?(namespace_id:)
        return unauthorized! unless Feature.enabled?(:work_items_realtime, current_user)

        namespace = force(GitlabSchema.find_by_gid(namespace_id))

        return unauthorized! if namespace.nil?

        # Require at least GUEST so MINIMAL_ACCESS users (admitted by the default access
        # level on some namespaces) cannot subscribe to a private namespace's changes.
        return unauthorized! unless namespace.member?(current_user, Gitlab::Access::GUEST)

        # On the update phase, re-check the specific work item so that a member who
        # cannot read a confidential work item is not disclosed its ID or action.
        #
        # NOTE: `authorized?` runs once per subscriber per triggered event, so this
        # loads the same record N times when N users are subscribed. Once the trigger
        # is added, pass the already-loaded WorkItem in the payload instead of a bare
        # id so this becomes an in-memory check (and so `:deleted` can be authorized
        # against the record captured before destroy).
        if object
          work_item = WorkItem.find_by_id(object[:work_item_id])

          return unauthorized! unless work_item && Ability.allowed?(current_user, :read_work_item, work_item)
        end

        true
      end
    end
  end
end
