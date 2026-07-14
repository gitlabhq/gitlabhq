# frozen_string_literal: true

module Namespaces
  module Stateful
    # StatePrecedence defines the ordering of propagation-relevant namespace states
    # and provides logic for determining which descendant states may be overwritten
    # when a state change propagates down the namespace hierarchy.
    #
    # Higher precedence states "win" over lower ones, meaning a descendant already
    # in a higher-precedence state will not be overwritten by a lower-precedence
    # propagation. The precedence order is maintenance > deletion_scheduled >
    # archived > ancestor_inherited. Forward propagation overwrites states below
    # the target's precedence; a reversal (transitioning back to the default
    # state, or exiting maintenance) overwrites states up to and including the
    # source's precedence.
    module StatePrecedence
      # Values mirror the canonical Namespace state enum, so :maintenance (the
      # highest-precedence propagated state) uses the enum's integer 6 rather
      # than a contiguous rank. Only the ordering matters for precedence
      # comparisons, and 6 > 2 > 1 > 0 preserves maintenance > deletion_scheduled
      # > archived > ancestor_inherited.
      STATE_PRECEDENCE = {
        ancestor_inherited: 0,
        archived: 1,
        deletion_scheduled: 2,
        maintenance: 6
      }.freeze

      # Returns the array of descendant states that may be overwritten when
      # propagating +target_state+ from a namespace whose previous state was
      # +source_state+.
      #
      # The overwritable set is derived purely from the precedence ordering,
      # in two directions:
      #
      # - Forward propagation (transitioning to a higher- or equal-precedence
      #   state, e.g. archive, schedule deletion, enter maintenance): overwrite
      #   every state with strictly lower precedence than the target. This always
      #   includes :ancestor_inherited (precedence 0, the default state).
      #
      # - Reversal (transitioning back to :ancestor_inherited, or exiting
      #   maintenance): overwrite every non-default state up to and including the
      #   source's precedence. For example:
      #     - unarchive (archived -> ancestor_inherited): [:archived]
      #     - restore (deletion_scheduled -> ancestor_inherited):
      #       [:archived, :deletion_scheduled]
      #     - exit maintenance (maintenance -> *):
      #       [:archived, :deletion_scheduled, :maintenance]
      #   Exiting maintenance is a reversal regardless of the (possibly
      #   non-propagated, e.g. transfer_scheduled) state the source lands in,
      #   so it is detected from the source rather than the target.
      #
      # @param source_state [Symbol] the state the source namespace is leaving
      # @param target_state [Symbol] the state being propagated to descendants
      # @return [Array<Symbol>] states that descendants may be transitioned away from
      def self.overwritable_states(source_state, target_state)
        source_precedence = STATE_PRECEDENCE[source_state]
        target_precedence = STATE_PRECEDENCE[target_state]

        if reversal?(source_state, target_state)
          # The source is at least propagation-relevant; log and bail otherwise.
          if source_precedence.nil?
            log_non_propagatable_state(source_state, target_state, target_precedence, source_precedence)
            return []
          end

          STATE_PRECEDENCE.select { |_, precedence| precedence.between?(1, source_precedence) }.keys
        else
          # Forward propagation only requires the target to be propagatable; the
          # overwritable set is derived solely from the target's precedence. The
          # source may legitimately be a non-propagated state (e.g. entering
          # maintenance from transfer_scheduled), which does not affect the set of
          # descendants that get overwritten.
          if target_precedence.nil?
            log_non_propagatable_state(source_state, target_state, target_precedence, source_precedence)
            return []
          end

          STATE_PRECEDENCE.select { |_, precedence| precedence < target_precedence }.keys
        end
      end

      # A reversal is either an explicit transition back to the default state, or
      # exiting maintenance (the highest-precedence state) to any state.
      def self.reversal?(source_state, target_state)
        target_state == :ancestor_inherited || source_state == :maintenance
      end

      def self.log_non_propagatable_state(source_state, target_state, target_precedence, source_precedence)
        non_propagatable = []
        non_propagatable << source_state if source_precedence.nil?
        non_propagatable << target_state if target_precedence.nil? && non_propagatable.exclude?(target_state)

        Gitlab::AppLogger.error(
          message: 'Non-propagatable state encountered in state precedence lookup',
          source_state: source_state,
          target_state: target_state,
          non_propagatable_states: non_propagatable,
          propagated_states: Namespaces::Stateful::PROPAGATED_STATES
        )
      end

      private_class_method :log_non_propagatable_state, :reversal?
    end
  end
end
