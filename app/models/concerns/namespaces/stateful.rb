# frozen_string_literal: true

module Namespaces
  module Stateful
    extend ActiveSupport::Concern

    # setting ancestor_inherited default as nil state means this namespace
    # doesn't have its own state and it inherits behavior from ancestors.
    STATES = {
      ancestor_inherited: nil,
      archived: 1,
      deletion_scheduled: 2,
      creation_in_progress: 3,
      deletion_in_progress: 4,
      transfer_in_progress: 5,
      maintenance: 6
    }.with_indifferent_access.freeze

    included do
      state_machine :state, initial: :ancestor_inherited do
        STATES.each_key do |state_name|
          state state_name.to_sym, value: STATES[state_name]
        end

        event :archive do
          transition ancestor_inherited: :archived
        end

        event :unarchive do
          transition archived: :ancestor_inherited
        end

        event :schedule_deletion do
          transition %i[ancestor_inherited archived] => :deletion_scheduled
        end

        event :start_deletion do
          transition deletion_scheduled: :deletion_in_progress
        end

        before_transition :validate_ancestors_state
        before_transition :update_state_metadata
        after_failure :handle_transition_failure

        after_transition any => any do |namespace, transition|
          Gitlab::AppLogger.info(
            message: 'Namespace state transition',
            namespace_id: namespace.id,
            from_state: transition.from_name,
            to_state: transition.to_name,
            event: transition.event,
            user_id: transition.args.dig(0, :current_user)&.id,
            correlation_id: transition.args.dig(0, :correlation_id) || Labkit::Correlation::CorrelationId.current_id
          )
        end
      end

      # Returns the effective state for this namespace, considering ancestor inheritance.
      # If the namespace has its own explicit state (not ancestor_inherited), returns that state.
      # Otherwise, traverses up the ancestor hierarchy to find the first ancestor with an explicit state.
      # Returns :ancestor_inherited if no ancestor has an explicit state.
      #
      # @return [Symbol] the effective state name
      def effective_state
        # Namespace has explicit state of its own or is a root namespace
        return state_name if !ancestor_inherited? || parent_id.nil?

        # Return state from closest ancestor
        closest_ancestor_state =
          self.class
              .where(id: traversal_ids)
              .where.not(state: STATES[:ancestor_inherited])
              .order(Arel.sql("array_length(traversal_ids, 1) DESC"))
              .pick(:state)

        STATES.key(closest_ancestor_state)&.to_sym
      end

      private

      def validate_ancestors_state(transition)
        return true if ancestors.empty?

        forbidden_states = forbidden_ancestors_states_for(transition.event)
        return true if forbidden_states.empty?

        ancestor_in_forbidden_state = ancestors.where(state: state_values(forbidden_states)).first
        return true unless ancestor_in_forbidden_state

        errors.add(
          :state,
          format(
            "cannot be changed as ancestor ID %{id} is %{state_name}",
            id: ancestor_in_forbidden_state.id,
            state_name: ancestor_in_forbidden_state.state_name
          )
        )

        false
      end

      def forbidden_ancestors_states_for(event)
        case event
        when :archive
          %i[archived deletion_in_progress deletion_scheduled]
        when :unarchive, :schedule_deletion
          %i[deletion_in_progress deletion_scheduled]
        else
          []
        end
      end

      def state_values(states)
        Array.wrap(states).map { |s| STATES[s] }
      end

      def transition_options(transition)
        transition.args.first || {}
      end

      def transition_correlation_id(transition)
        transition_options(transition)[:correlation_id] || Labkit::Correlation::CorrelationId.current_id
      end

      def update_state_metadata(transition, error: nil)
        options = transition_options(transition)

        metadata_update = {
          last_updated_at: Time.current,
          last_error: error,
          last_changed_by_user_id: options[:current_user]&.id,
          correlation_id: transition_correlation_id(transition)
        }

        namespace_details.state_metadata.merge!(metadata_update)
      end

      def handle_transition_failure(transition)
        error_message = build_transition_error_message(transition)

        update_state_metadata(transition, error: error_message)
        namespace_details.save!

        options = transition_options(transition)

        Gitlab::AppLogger.error(
          message: 'Namespace state transition failed',
          namespace_id: id,
          event: transition.event,
          current_state: state_name,
          error: error_message,
          user_id: options[:current_user]&.id,
          correlation_id: transition_correlation_id(transition)
        )
      end

      def build_transition_error_message(transition)
        base_message = "Cannot transition from #{transition.from_name} to #{transition.to_name} via #{transition.event}"

        reasons = []
        reasons << errors[:state].join(', ') if errors[:state].present?

        if reasons.any?
          "#{base_message}: #{reasons.join('; ')}"
        else
          "#{base_message}: unknown reason"
        end
      end
    end
  end
end
