# frozen_string_literal: true

module Namespaces
  # Applies a pending state propagation for a namespace subtree.
  #
  # Looks up the pending outbox record for (namespace_id, target_state),
  # computes the overwritable states, marks the record `processing`, walks the
  # descendant subtree in batches applying a conditional bulk update, and
  # deletes the record on completion.
  #
  # See https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/group_and_project_operations_and_state_management/decisions/003_state_propagation_model/
  class StatePropagationService
    STATE_PROPAGATION_ITERATOR_BATCH_SIZE = 200

    # Key under which a descendant's pre-deletion state is preserved, shared with StatePreservation.
    DELETION_PRESERVATION_KEY = 'schedule_deletion'

    def initialize(namespace_id, target_state)
      @namespace_id = namespace_id
      @target_state = target_state
    end

    def execute
      propagation = Namespaces::StatePropagation.next_pending_for(namespace_id, target_state)
      return if propagation.nil?

      overwritable_states = Namespaces::Stateful::StatePrecedence.overwritable_states(
        propagation.source_state.to_sym,
        propagation.target_state.to_sym
      )

      # Nothing to propagate: drop the outbox record without a wasted status write.
      if overwritable_states.empty?
        propagation.destroy!
        return
      end

      return unless propagation.claim

      start_time = ::Gitlab::Metrics::System.monotonic_time

      # These steps are intentionally not wrapped in a single transaction: propagation
      # can update very large descendant subtrees in batches, and one transaction would
      # hold locks for too long. If it fails mid-run the record stays `processing` and
      # StatePropagationCronWorker reclaims and re-enqueues it.
      propagate(propagation, overwritable_states)

      propagation.destroy!

      Gitlab::NamespaceStatePropagation::Metrics.observe_duration(
        propagation.target_state,
        ::Gitlab::Metrics::System.monotonic_time - start_time
      )
    end

    private

    attr_reader :namespace_id, :target_state

    def propagate(propagation, overwritable_states)
      source_state = propagation.source_state
      target_state = propagation.target_state
      cursor = { current_id: namespace_id, depth: [namespace_id] }

      # The traversal must keep descending through the origin namespace (already in
      # target_state) as well as descendants still in an overwritable state, so the
      # filter includes target_state. The conditional UPDATE below guarantees only
      # overwritable descendants actually change state.
      # Normalise to symbols so the filter never mixes symbol and string states.
      state_filter = (overwritable_states + [target_state.to_sym]).uniq

      iterator = Gitlab::Database::Namespaces::StatePropagationIterator.new(
        cursor: cursor,
        state_filter: state_filter,
        on_rewind: -> { Gitlab::NamespaceStatePropagation::Metrics.increment_boundary_rewinds }
      )

      iterator.each_batch(of: STATE_PROPAGATION_ITERATOR_BATCH_SIZE) do |ids|
        Namespace.overwrite_state_in_batch(
          ids,
          from: overwritable_states,
          to: target_state,
          **preservation_options(source_state, target_state)
        )

        # Heartbeat: keeps a long-running propagation from being treated as stuck by
        # StatePropagationCronWorker and re-run concurrently.
        propagation.touch(:started_at)

        Gitlab::NamespaceStatePropagation::Metrics.increment_batches(target_state)
      end
    end

    def preservation_options(source_state, target_state)
      # Exiting maintenance into deletion_scheduled is a reversal: descendants keep what they preserved.
      if target_state == 'deletion_scheduled' && source_state != 'maintenance'
        { preserve_event: DELETION_PRESERVATION_KEY }
      elsif source_state == 'archived' && target_state == 'ancestor_inherited'
        { clear_preserved: true }
      else
        {}
      end
    end
  end
end
