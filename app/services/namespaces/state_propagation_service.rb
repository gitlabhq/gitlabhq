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
    STATE_PROPAGATION_ITERATOR_BATCH_SIZE = 500

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

      propagation.update!(status: :processing, started_at: Time.current)

      # These steps are intentionally not wrapped in a single transaction: propagation
      # can update very large descendant subtrees in batches, and one transaction would
      # hold locks for too long. If it fails mid-run the record stays `processing` and
      # StatePropagationCronWorker reclaims and re-enqueues it.
      propagate(propagation.target_state, overwritable_states)

      propagation.destroy!
    end

    private

    attr_reader :namespace_id, :target_state

    def propagate(target_state, overwritable_states)
      cursor = { current_id: namespace_id, depth: [namespace_id] }

      # The traversal must keep descending through the origin namespace (already in
      # target_state) as well as descendants still in an overwritable state, so the
      # filter includes target_state. The conditional UPDATE below guarantees only
      # overwritable descendants actually change state.
      # Normalise to symbols so the filter never mixes symbol and string states.
      state_filter = (overwritable_states + [target_state.to_sym]).uniq

      iterator = Gitlab::Database::Namespaces::StatePropagationIterator.new(
        cursor: cursor,
        state_filter: state_filter
      )

      iterator.each_batch(of: STATE_PROPAGATION_ITERATOR_BATCH_SIZE) do |ids|
        Namespace.overwrite_state_in_batch(ids, from: overwritable_states, to: target_state)
      end
    end
  end
end
