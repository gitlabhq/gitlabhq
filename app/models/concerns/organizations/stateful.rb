# frozen_string_literal: true

module Organizations
  module Stateful
    extend ActiveSupport::Concern

    # States in which an organization is being deleted. These are hidden from
    # non-admin users (see Organizations::OrganizationsFinder).
    DELETION_STATES = %i[soft_deleted deletion_in_progress].freeze

    # States in which an organization is in read-only mode (writes blocked).
    # Use the `read_only?` predicate rather than checking individual states.
    # Enforcement layers should call `read_only?` so that gating can be added
    # cleanly behind a feature flag in a follow-up MR
    # (see https://gitlab.com/gitlab-org/gitlab/-/issues/602810).
    READ_ONLY_STATES = %i[read_only_initialization read_only].freeze

    # Valid reasons for entering read-only mode.
    # Persisted in OrganizationDetail#state_metadata as `read_only_reason`.
    READ_ONLY_REASONS = %w[migration isolation incident billing legal].freeze

    # Reasons that are expected to resolve on their own within a bounded time.
    # Enforcement layers return a retryable response (503 + Retry-After) for
    # these, and a non-retryable response (403) for the remaining indefinite
    # reasons.
    #
    # This classification is an implementation decision: ADR 010 (Organization
    # Read-Only Mode) lists the reasons but does not say which are time-bounded.
    # The error matrix that defines the mapping is the source of truth:
    # https://gitlab.com/gitlab-org/gitlab/-/work_items/602825.
    TIME_BOUNDED_READ_ONLY_REASONS = %w[migration incident].freeze

    # Non-active states from which read-only mode cannot be entered. An
    # organization must be active first; the state machine enforces this via the
    # `active -> read_only_initialization` transition.
    READ_ONLY_BLOCKED_STATES = (DELETION_STATES + %i[unconfirmed confirmed]).freeze

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
        read_only_initialization: 5,
        read_only: 6
      }, instance_methods: false

      scope :excluding_deletion_states, -> { where.not(state: DELETION_STATES) }
      scope :in_read_only_states, -> { where(state: READ_ONLY_STATES) }

      state_machine :state, initial: :unconfirmed do
        before_transition :update_state_metadata
        before_transition on: [:soft_delete, :hard_delete, :abort_hard_deletion, :restore], do: :ensure_transition_user
        before_transition on: [:soft_delete, :hard_delete], do: :ensure_organization_is_empty
        before_transition on: :soft_delete, do: :set_soft_deletion_data
        before_transition on: :restore, do: :clear_soft_deletion_data
        before_transition on: :confirm, do: :ensure_confirmed_by_user
        before_transition on: :confirm, do: :set_confirmation_data
        before_transition on: [:start_read_only, :confirm_read_only], do: :ensure_not_default_organization
        before_transition on: :start_read_only, do: :set_read_only_data
        before_transition on: [:cancel_read_only, :exit_read_only], do: :clear_read_only_data

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

        # Begins the read-only transition: writes are blocked while the
        # organization drains outstanding work.
        event :start_read_only do
          transition active: :read_only_initialization
        end

        # Completes the read-only transition: the organization is fully drained
        # and enters the steady read-only state.
        event :confirm_read_only do
          transition read_only_initialization: :read_only
        end

        # Cancels a read-only transition before it completes (drain aborted).
        event :cancel_read_only do
          transition read_only_initialization: :active
        end

        # Exits the steady read-only state and returns the organization to active.
        event :exit_read_only do
          transition read_only: :active
        end

        after_transition :log_transition
        after_failure    :update_state_metadata_on_failure
        after_failure    :log_transition_failure
      end

      # Returns true when the organization is in any read-only state.
      # Enforcement layers MUST call this predicate rather than checking
      # individual states, so that a feature flag can gate the behaviour
      # cleanly in a follow-up MR (https://gitlab.com/gitlab-org/gitlab/-/issues/602810).
      def read_only?
        READ_ONLY_STATES.include?(state_name)
      end

      def read_only_time_bounded?
        TIME_BOUNDED_READ_ONLY_REASONS.include?(read_only_reason)
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

      # Guards entry into read-only states: the default organization must never
      # enter read-only mode because it hosts all self-managed resources. Guards
      # both read-only events as defense-in-depth: `confirm_read_only` is
      # unreachable for the default org in normal flow (it can never reach
      # `read_only_initialization`), but the guard backstops the invariant against
      # abnormal paths such as migrations, console fixes, or future transitions.
      def ensure_not_default_organization(transition)
        return true unless self.class.default?(id)

        errors.add(:state, "#{transition.event} transition is not allowed for the default organization")
        false
      end

      def set_read_only_data(transition)
        reason = transition_args(transition)[:read_only_reason]

        unless READ_ONLY_REASONS.include?(reason.to_s)
          errors.add(:state, "#{transition.event} transition requires a valid read_only_reason " \
            "(#{READ_ONLY_REASONS.join(', ')})")
          return false
        end

        state_metadata.merge!(read_only_reason: reason.to_s)
      end

      def clear_read_only_data(_transition)
        state_metadata.except!('read_only_reason')
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
