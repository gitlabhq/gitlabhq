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

      MEMBERSHIP_CACHE_TTL = 3.minutes

      payload_type Types::WorkItems::NamespaceWorkItemChangesPayloadType

      argument :namespace_id, ::Types::GlobalIDType[::Namespace],
        required: true,
        description: 'Namespace to receive work item updates for.'

      def authorized?(namespace_id:)
        return unauthorized! unless Feature.enabled?(:work_items_realtime, current_user)
        return unauthorized! unless current_user
        return unauthorized! unless member?(namespace_id)

        true
      end

      private

      # Cached because this runs once per subscriber per event, so its queries would otherwise repeat for every
      # subscriber on every change (up to four per miss: the namespace, two organization lookups, the membership).
      # Only positive verdicts are cached: a denial fails the subscribe or unsubscribes the update, so it never
      # repeats. Tradeoff: revoked access stays cached for the TTL, which is acceptable because the broadcast carries
      # only a work item id and an action, and clients refetch the item under per-user authorization.
      def member?(namespace_id)
        cache_key = ['work_items', 'namespace_changes', 'member', current_user.id, namespace_id.to_s]

        return true if Rails.cache.read(cache_key)

        namespace = force(GitlabSchema.find_by_gid(namespace_id))

        # Require GUEST: MINIMAL_ACCESS users are admitted by some namespaces' default access level.
        return false unless namespace&.member?(current_user, Gitlab::Access::GUEST)

        Rails.cache.write(cache_key, true, expires_in: MEMBERSHIP_CACHE_TTL)

        true
      end
    end
  end
end
