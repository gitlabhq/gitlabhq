# frozen_string_literal: true

module Namespaces
  module Stateful
    # State Preservation allows the state machine to "remember" the state a namespace
    # was in before a transition, so it can be restored later when a corresponding
    # reverse transition occurs.
    #
    # Example flow:
    #   1. Namespace is in :archived state
    #   2. User triggers :schedule_deletion -> state becomes :deletion_scheduled
    #      - The previous state (:archived) is saved to state_metadata
    #   3. User triggers :cancel_deletion -> state is restored to :archived
    #      - The preserved state is read and used to determine the target state
    #      - The preserved state is then cleared from state_metadata
    #
    # Without preservation, cancel_deletion would always return to :ancestor_inherited,
    # losing the fact that the namespace was archived before deletion was scheduled.
    #
    # ## How STATE_MEMORY_CONFIG works
    #
    # The config maps preserve events to their corresponding restore events:
    #
    #   STATE_MEMORY_CONFIG = {
    #     schedule_deletion: :cancel_deletion   # key = preserve, value = restore
    #   }
    #
    # Preserved states are stored in state_metadata under the preserve event's name:
    #
    #   state_metadata = {
    #     'preserved_states' => {
    #       'schedule_deletion' => 'archived'
    #     }
    #   }
    #
    # When a restore event occurs (e.g., :cancel_deletion), we perform a reverse
    # lookup using Hash#key to find the corresponding preserve event, then use
    # that key to retrieve and clear the preserved state.
    module StatePreservation
      # Maps events that should preserve state to their corresponding restore events.
      # Key: event that triggers state preservation (saves the "from" state)
      # Value: event that triggers state restoration (restores to the saved state)
      #
      # @example With schedule_deletion => cancel_deletion
      #   # When :schedule_deletion fires, the current state is saved
      #   # When :cancel_deletion fires, the saved state is restored and cleared
      #
      # @example With start_deletion => reschedule_deletion
      #   # When :start_deletion fires on a child namespace (not explicitly scheduled),
      #   # the current state is saved so it can be restored if deletion fails
      #   # When :reschedule_deletion fires, the saved state is restored and cleared
      STATE_MEMORY_CONFIG = {
        schedule_deletion: :cancel_deletion,
        start_deletion: :reschedule_deletion,
        start_transfer: [:complete_transfer, :cancel_transfer]
      }.freeze

      private

      # Main entry point called during state transitions.
      # Handles both preservation (on preserve events) and cleanup (on restore events).
      #
      # @param transition [StateMachine::Transition] the current transition object
      def handle_state_preservation(transition)
        preserve_event = preserve_event_for(transition.event)

        if preserve_event
          # This is a restore event (e.g., :cancel_deletion)
          # Clean up the preserved state since restoration is complete
          clear_preserved_state(preserve_event)
        elsif preserve_previous_state?(transition.event)
          # This is a preserve event (e.g., :schedule_deletion)
          # Save the current state so we can restore it later
          save_preserved_state(transition.event, transition.from_name)
        end
      end

      # Checks if the given event should trigger state preservation.
      #
      # @param event [Symbol] the transition event
      # @return [Boolean] true if this event should save the current state
      def preserve_previous_state?(event)
        STATE_MEMORY_CONFIG.key?(event)
      end

      # Finds the preserve event that corresponds to a given restore event.
      # Performs a reverse lookup on STATE_MEMORY_CONFIG.
      # Supports both single restore events and arrays of restore events.
      #
      # This is needed because preserved states are stored under the preserve event's name.
      # When handling a restore event like :cancel_deletion, we need to find its
      # corresponding preserve event (:schedule_deletion) to look up and clear the
      # preserved state.
      #
      # @example
      #   preserve_event_for(:cancel_deletion)   # => :schedule_deletion
      #   preserve_event_for(:complete_transfer)  # => :start_transfer
      #   preserve_event_for(:cancel_transfer)      # => :start_transfer
      #   preserve_event_for(:schedule_deletion)  # => nil (not a restore event)
      #
      # @param restore_event [Symbol] the restore event (e.g., :cancel_deletion)
      # @return [Symbol, nil] the corresponding preserve event, or nil if not found
      def preserve_event_for(restore_event)
        STATE_MEMORY_CONFIG.find { |_, restore| Array(restore).include?(restore_event) }&.first
      end

      # Persists the current state to state_metadata before transitioning.
      # Stored under 'preserved_states' hash, keyed by the event name.
      #
      # @param event [Symbol] the preserve event (used as storage key)
      # @param state_name [Symbol] the state to preserve
      def save_preserved_state(event, state_name)
        state_metadata['preserved_states'] ||= {}
        state_metadata['preserved_states'][event.to_s] = state_name.to_s
      end

      # Removes the preserved state after restoration is complete.
      # Cleans up the 'preserved_states' hash if it becomes empty.
      #
      # @param event [Symbol] the preserve event whose state should be cleared
      def clear_preserved_state(event)
        return unless state_metadata['preserved_states']

        state_metadata['preserved_states'].delete(event.to_s)
        state_metadata.delete('preserved_states') if state_metadata['preserved_states'].empty?
      end

      # Retrieves the preserved state for a given preserve event.
      #
      # @param event [Symbol] the preserve event (e.g., :schedule_deletion)
      # @return [Symbol, nil] the preserved state name, or nil if none exists
      def preserved_state(event)
        state_metadata.dig('preserved_states', event.to_s)&.to_sym
      end

      # Checks if the preserved state matches a target state.
      # Used in transition guards to determine the correct restore target.
      #
      # @param event [Symbol] the preserve event to check
      # @param target_state [Symbol] the state to compare against
      # @return [Boolean] true if the preserved state matches the target
      def should_restore_to?(event, target_state)
        preserved_state(event) == target_state
      end

      # Guard method used in state machine transition definitions.
      # Determines if cancel_deletion should restore to :archived state.
      #
      # @return [Boolean] true if the namespace was archived before deletion was scheduled
      def restore_to_archived_on_cancel_deletion?
        preserve_event = preserve_event_for(:cancel_deletion)
        should_restore_to?(preserve_event, :archived)
      end

      # Guard method used in state machine transition definitions.
      # Determines if reschedule_deletion should restore to :archived state.
      #
      # @return [Boolean] true if the namespace was archived before deletion started
      def restore_to_archived_on_reschedule_deletion?
        preserve_event = preserve_event_for(:reschedule_deletion)
        should_restore_to?(preserve_event, :archived)
      end

      # Guard method used in state machine transition definitions.
      # Determines if reschedule_deletion should restore to :ancestor_inherited state.
      # This is used for child namespaces that were not explicitly scheduled for deletion
      # but were being deleted because their parent was scheduled.
      #
      # @return [Boolean] true if the namespace was in ancestor_inherited before deletion started
      def restore_to_ancestor_inherited_on_reschedule_deletion?
        preserve_event = preserve_event_for(:reschedule_deletion)
        should_restore_to?(preserve_event, :ancestor_inherited)
      end

      # Guard method used in state machine transition definitions.
      # Determines if reschedule_deletion should restore to :deletion_scheduled state.
      # This is used for namespaces that were explicitly scheduled for deletion.
      #
      # @return [Boolean] true if the namespace was in deletion_scheduled before deletion started
      def restore_to_deletion_scheduled_on_reschedule_deletion?
        preserve_event = preserve_event_for(:reschedule_deletion)
        should_restore_to?(preserve_event, :deletion_scheduled)
      end

      # Guard method used in state machine transition definitions.
      # Determines if complete_transfer should restore to :archived state.
      #
      # @return [Boolean] true if the namespace was in archived before transfer started
      def restore_to_archived_on_complete_transfer?
        preserve_event = preserve_event_for(:complete_transfer)
        should_restore_to?(preserve_event, :archived)
      end

      # Guard method used in state machine transition definitions.
      # Determines if cancel_transfer should restore to :archived state.
      #
      # @return [Boolean] true if the namespace was in archived before transfer started
      def restore_to_archived_on_cancel_transfer?
        preserve_event = preserve_event_for(:cancel_transfer)
        should_restore_to?(preserve_event, :archived)
      end
    end
  end
end
