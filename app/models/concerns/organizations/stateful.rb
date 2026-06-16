# frozen_string_literal: true

module Organizations
  module Stateful
    extend ActiveSupport::Concern

    # States in which an organization is being deleted. These are hidden from
    # non-admin users (see Organizations::OrganizationsFinder).
    DELETION_STATES = %i[soft_deleted deletion_in_progress].freeze

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
        active: 4
      }, instance_methods: false

      scope :excluding_deletion_states, -> { where.not(state: DELETION_STATES) }

      state_machine :state, initial: :unconfirmed do
        before_transition :update_state_metadata
        before_transition on: [:soft_delete, :hard_delete, :abort_hard_deletion], do: :ensure_transition_user
        before_transition on: [:soft_delete, :hard_delete], do: :ensure_organization_is_empty
        before_transition on: :soft_delete, do: :set_soft_deletion_data
        before_transition on: :restore, do: :clear_soft_deletion_data
        before_transition on: :confirm, do: :ensure_confirmed_by_user
        before_transition on: :confirm, do: :set_confirmation_data

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

        after_transition :log_transition
        after_failure    :update_state_metadata_on_failure
        after_failure    :log_transition_failure
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

      def stateful_detail
        organization_detail
      end

      def stateful_log_metadata
        { message: 'Organization state transition', organization_id: id }
      end
    end
  end
end
