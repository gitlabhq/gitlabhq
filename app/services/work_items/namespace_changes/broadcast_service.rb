# frozen_string_literal: true

module WorkItems
  module NamespaceChanges
    # Broadcasts { work_item_id, action } to namespaceWorkItemChanges for the work item's namespace and each ancestor.
    #
    # Subscribers get no per-item authorization (see Subscriptions::WorkItems::NamespaceWorkItemChanges), so filtering
    # happens here - and only on the item itself; per-member restrictions are out of reach.
    class BroadcastService
      RELEVANT_CHANGES = %w[
        assignees
        confidential
        due_date
        health_status
        hierarchy_widget
        iteration_widget
        labels
        milestone_id
        sprint_id
        start_and_due_date_widget
        start_date
        state_id
        status_widget
        title
        weight
      ].freeze

      def initialize(work_item, action:, updated_changes: nil)
        @work_item = work_item
        @action = action
        @updated_changes = Array(updated_changes)
      end

      def execute
        return unless broadcast?

        # Primitives only: an AR payload is reloaded once per subscriber, and cannot be reloaded at all for :deleted.
        payload = { work_item_id: work_item.id, action: action }

        target_namespaces.each do |namespace|
          next if rate_limited?(namespace)

          ::GitlabSchema.subscriptions.trigger(
            'namespaceWorkItemChanges',
            { namespace_id: namespace.to_gid },
            payload
          )
        end
      end

      private

      attr_reader :work_item, :action, :updated_changes

      # Ordered cheapest-first, so no-op updates bail out before touching the database.
      def broadcast?
        relevant_change? &&
          Feature.enabled?(:work_items_realtime_broadcast, root_ancestor) &&
          (!work_item.confidential? || confidential_flip?) &&
          subject_level_readable?
      end

      def relevant_change?
        return true unless action == :updated

        (updated_changes & RELEVANT_CHANGES).present?
      end

      # The sole broadcast a confidential item gets. The payload carries no data, so every subscriber refetches by id
      # under per-user authorization: members who can still read it keep the row, everyone else drops it. The id
      # itself discloses nothing - it was public until this very change.
      def confidential_flip?
        action == :updated && updated_changes.include?('confidential')
      end

      # Budgeted per delivered namespace, not per hierarchy: a storm in one project (e.g. a CSV import) exhausts only
      # its own chain, so sibling namespaces keep broadcasting. Shared ancestors still share their budget.
      def rate_limited?(namespace)
        Gitlab::ApplicationRateLimiter.throttled?(:namespace_work_item_changes_broadcast, scope: namespace)
      end

      # Subject-level only: this runs once per event, so per-member conditions cannot be answered. PRIVATE issues need
      # no check - every subscriber holds at least GUEST, which descendant projects inherit.
      #
      # Known gap: `user_banned_from_namespace` is per-user, so banned members still receive events.
      def subject_level_readable?
        return false if work_item.hidden?
        return false if work_item.project && !work_item.project.issues_enabled?

        # External authorization decides project access per user via an external service, so membership implies nothing
        # while it is on (ProjectPolicy's `external_authorization_enabled & ~classification_label_authorized`).
        return false if work_item.project && ::Gitlab::ExternalAuthorization.perform_check?

        !prevented_by_work_item_policy?
      end

      # Hand-rolled rather than `banned?`, which cannot work here: with no enable steps its Runner short-circuits to
      # prevented and returns true without evaluating a single rule.
      #
      # `global_actions` walks the superclass chain only, so container rules behind IssuablePolicy's `delegate` are
      # excluded. That is required: ProjectPolicy's `anonymous & ~public_project` would veto every private project.
      # Evaluating with no user leaves subject-only rules exact and user-dependent ones fail-closed.
      def prevented_by_work_item_policy?
        policy = Ability.policy_for(nil, work_item)

        policy.class.global_actions.any? do |rule_action, rule, exceptions|
          rule_action == :prevent && exceptions.blank? && rule.pass?(policy)
        end
      end

      def target_namespaces
        # skope: the default STI scope would drop Group ancestors; select: to_gid needs id + type.
        @target_namespaces ||=
          Gitlab::SafeRequestStore.fetch([:namespace_work_item_changes_targets, work_item.namespace_id]) do
            work_item.namespace.self_and_ancestors(skope: ::Namespace).select(:id, :type).to_a
          end
      end

      def root_ancestor
        @root_ancestor ||= target_namespaces.find { |namespace| namespace.id == root_ancestor_id } ||
          work_item.namespace.root_ancestor
      end

      def root_ancestor_id
        work_item.namespace.traversal_ids.first
      end
    end
  end
end
