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
        state :ancestor_inherited, value: STATES[:ancestor_inherited]
        state :archived, value: STATES[:archived]
        state :deletion_scheduled, value: STATES[:deletion_scheduled]
        state :creation_in_progress, value: STATES[:creation_in_progress]
        state :deletion_in_progress, value: STATES[:deletion_in_progress]
        state :transfer_in_progress, value: STATES[:transfer_in_progress]
        state :maintenance, value: STATES[:maintenance]

        event :start_transfer do
          transition [:ancestor_inherited] => :transfer_in_progress
        end

        event :complete_transfer do
          transition [:transfer_in_progress] => :ancestor_inherited
        end

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

      def update_state_metadata(transition, error: nil)
        options = transition.args.first || {}
        current_user = options[:current_user]
        correlation_id = options[:correlation_id] || Labkit::Correlation::CorrelationId.current_id

        metadata_update = {
          last_updated_at: Time.current,
          last_error: error,
          last_changed_by_user_id: current_user&.id,
          correlation_id: correlation_id
        }

        namespace_details.state_metadata.merge!(metadata_update)
      end

      def handle_transition_failure(transition)
        error_message = if errors[:state].present?
                          errors[:state].join(', ')
                        else
                          "Unknown transition failure"
                        end

        update_state_metadata(transition, error: error_message)
        namespace_details.save!

        options = transition.args.first || {}
        correlation_id = options[:correlation_id] || Labkit::Correlation::CorrelationId.current_id

        Gitlab::AppLogger.error(
          message: 'Namespace state transition failed',
          namespace_id: id,
          event: transition.event,
          current_state: state_name,
          error: error_message,
          user_id: options[:current_user]&.id,
          correlation_id: correlation_id
        )
      end
    end
  end
end
