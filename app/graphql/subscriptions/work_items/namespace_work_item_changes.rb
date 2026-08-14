# frozen_string_literal: true

module Subscriptions
  module WorkItems
    # Authorization is namespace-level only, deliberately: this runs once per subscriber per event, so a per-item check
    # would not scale. Item-intrinsic exclusions (confidential, hidden, ...) are applied once per event at the trigger -
    # see WorkItems::NamespaceChanges::BroadcastService.
    #
    # Net effect: GUEST on this namespace sees the id and action of every remaining work item in the subtree.
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

        # Require GUEST: MINIMAL_ACCESS users are admitted by some namespaces' default access level.
        return unauthorized! unless namespace.member?(current_user, Gitlab::Access::GUEST)

        true
      end
    end
  end
end
