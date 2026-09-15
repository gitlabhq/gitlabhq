# frozen_string_literal: true

module Organizations
  module Stateful
    extend ActiveSupport::Concern

    # States in which an organization is being deleted. These are hidden from
    # non-admin users (see Organizations::OrganizationsFinder).
    DELETION_STATES = %i[soft_deleted deletion_in_progress].freeze

    # Valid reasons for entering maintenance mode.
    # Persisted in OrganizationDetail#state_metadata as `maintenance_reason`.
    MAINTENANCE_REASONS = %w[migration isolation incident billing legal].freeze

    # Reasons that are expected to resolve on their own within a bounded time.
    # Enforcement layers return a retryable response (503 + Retry-After) for
    # these, and a non-retryable response (403) for the remaining indefinite
    # reasons.
    #
    # This classification is an implementation decision: ADR 010 (Organization
    # Maintenance Mode) lists the reasons but does not say which are time-bounded.
    # The error matrix that defines the mapping is the source of truth:
    # https://gitlab.com/gitlab-org/gitlab/-/work_items/602825.
    TIME_BOUNDED_MAINTENANCE_REASONS = %w[migration incident].freeze

    MAINTENANCE_MODE_RETRY_AFTER_SECONDS = 60

    included do
      include ::Gitlab::TenantContainerLifecycle::Stateful::TransitionContext
      include ::Gitlab::TenantContainerLifecycle::Stateful::TransitionCallbacks
      include ::Gitlab::TenantContainerLifecycle::Stateful::TransitionLogging
      include ::Gitlab::TenantContainerLifecycle::Stateful::TransitionValidation

      attribute :state, :integer, limit: 2, default: 0

      enum :state, {
        unconfirmed: 0,
        soft_deleted: 1,
        deletion_in_progress: 2,
        confirmed: 3,
        active: 4,
        maintenance_initialization: 5,
        maintenance: 6
      }, instance_methods: false

      scope :excluding_deletion_states, -> { where.not(state: DELETION_STATES) }

      state_machine :state, initial: :unconfirmed do
        before_transition :update_state_metadata
        before_transition on: [:soft_delete, :hard_delete, :abort_hard_deletion, :restore], do: :ensure_transition_user
        before_transition on: [:soft_delete, :hard_delete], do: :ensure_organization_is_empty
        before_transition on: :soft_delete, do: :set_soft_deletion_data
        before_transition on: :restore, do: :clear_soft_deletion_data
        before_transition on: :confirm, do: :ensure_confirmed_by_user
        before_transition on: :confirm, do: :set_confirmation_data
        before_transition on: [:start_maintenance, :confirm_maintenance], do: :ensure_not_default_organization
        before_transition on: :start_maintenance, do: :set_maintenance_data
        before_transition on: [:cancel_maintenance, :exit_maintenance], do: :clear_maintenance_data

        event :confirm do
          transition unconfirmed: :confirmed
        end

        event :activate do
          transition confirmed: :active
        end

        event :soft_delete do
          transition active: :soft_deleted
        end

        event :hard_delete do
          transition soft_deleted: :deletion_in_progress
        end

        event :abort_hard_deletion do
          transition deletion_in_progress: :soft_deleted
        end

        event :restore do
          transition soft_deleted: :active
        end

        # Begins the maintenance transition: requests are blocked while the
        # organization drains outstanding work.
        event :start_maintenance do
          transition active: :maintenance_initialization
        end

        # Completes the maintenance transition: the organization is fully drained
        # and enters the steady maintenance state.
        event :confirm_maintenance do
          transition maintenance_initialization: :maintenance
        end

        # Cancels a maintenance transition before it completes (drain aborted).
        event :cancel_maintenance do
          transition maintenance_initialization: :active
        end

        # Exits the steady maintenance state and returns the organization to active.
        event :exit_maintenance do
          transition maintenance: :active
        end

        after_transition :log_transition
        after_failure    :update_state_metadata_on_failure
        after_failure    :log_transition_failure
      end

      def maintenance_time_bounded?
        TIME_BOUNDED_MAINTENANCE_REASONS.include?(maintenance_reason)
      end

      def maintenance_message
        if maintenance_time_bounded?
          _('This organization is temporarily unavailable due to maintenance.')
        else
          _('This organization is unavailable.')
        end
      end

      private

      def ensure_organization_is_empty(transition)
        return true if empty?

        errors.add(:state, "#{transition.event} transition requires the organization to be empty")
        false
      end

      def ensure_confirmed_by_user(transition)
        return true if confirmed_by_user(transition)

        errors.add(:state, "#{transition.event} transition needs confirmed_by_user")
        false
      end

      def confirmed_by_user(transition)
        transition_args(transition)[:confirmed_by_user]
      end

      def set_confirmation_data(transition)
        state_metadata.merge!(
          confirmed_at: Time.current.as_json,
          confirmed_by_user_id: confirmed_by_user(transition).id
        )
      end

      def set_soft_deletion_data(transition)
        self.soft_deleted_at = Time.current
        state_metadata.merge!(
          soft_deletion_scheduled_by_user_id: transition_user(transition).id
        )
      end

      def clear_soft_deletion_data(_transition)
        self.soft_deleted_at = nil
        state_metadata.except!('soft_deletion_scheduled_by_user_id')
      end

      # Guards entry into maintenance states: the default organization must never
      # enter maintenance mode because it hosts all self-managed resources. Guards
      # both maintenance events as defense-in-depth: `confirm_maintenance` is
      # unreachable for the default org in normal flow (it can never reach
      # `maintenance_initialization`), but the guard backstops the invariant against
      # abnormal paths such as migrations, console fixes, or future transitions.
      def ensure_not_default_organization(transition)
        return true unless self.class.default?(id)

        errors.add(:state, "#{transition.event} transition is not allowed for the default organization")
        false
      end

      def set_maintenance_data(transition)
        reason = transition_args(transition)[:maintenance_reason]

        unless MAINTENANCE_REASONS.include?(reason.to_s)
          errors.add(:state, "#{transition.event} transition requires a valid maintenance_reason " \
            "(#{MAINTENANCE_REASONS.join(', ')})")
          return false
        end

        state_metadata.merge!(maintenance_reason: reason.to_s)
      end

      def clear_maintenance_data(_transition)
        state_metadata.except!('maintenance_reason')
      end

      def stateful_detail
        organization_detail
      end

      def stateful_log_metadata
        { message: 'Organization state transition', organization_id: id }
      end
    end
  end
end
