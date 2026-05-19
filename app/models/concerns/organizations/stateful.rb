# frozen_string_literal: true

module Organizations
  module Stateful
    extend ActiveSupport::Concern

    included do
      include ::Gitlab::TenantContainerLifecycle::Stateful::TransitionContext
      include ::Gitlab::TenantContainerLifecycle::Stateful::TransitionCallbacks
      include ::Gitlab::TenantContainerLifecycle::Stateful::TransitionLogging
      include ::Gitlab::TenantContainerLifecycle::Stateful::TransitionValidation

      attribute :state, :integer, limit: 2, default: 0

      enum :state, {
        unconfirmed: 0,
        deletion_scheduled: 1,
        deletion_in_progress: 2,
        confirmed: 3,
        active: 4
      }, instance_methods: false

      state_machine :state, initial: :unconfirmed do
        before_transition :update_state_metadata
        before_transition on: :schedule_deletion, do: :ensure_transition_user
        before_transition on: :schedule_deletion, do: :ensure_organization_is_empty
        before_transition on: :schedule_deletion, do: :set_deletion_schedule_data
        before_transition on: :cancel_deletion, do: :clear_deletion_schedule_data
        # We don't call :set_deletion_schedule_data on :reschedule_deletion
        # as it would change the actual deletion date/time.
        before_transition on: :reschedule_deletion, do: :set_deletion_error_data
        before_transition on: :confirm, do: :ensure_confirmed_by_user
        before_transition on: :confirm, do: :set_confirmation_data

        event :confirm do
          transition unconfirmed: :confirmed
        end

        event :activate do
          transition confirmed: :active
        end

        event :schedule_deletion do
          transition active: :deletion_scheduled
        end

        event :start_deletion do
          transition deletion_scheduled: :deletion_in_progress
        end

        event :cancel_deletion do
          transition %i[deletion_scheduled deletion_in_progress] => :active
        end

        event :reschedule_deletion do
          transition deletion_in_progress: :deletion_scheduled
        end

        after_transition :log_transition
        after_failure    :update_state_metadata_on_failure
        after_failure    :log_transition_failure
      end

      private

      def ensure_organization_is_empty(_transition)
        return true if empty?

        errors.add(:state, 'schedule_deletion transition requires the organization to be empty')
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

      def stateful_detail
        organization_detail
      end

      def stateful_log_metadata
        { message: 'Organization state transition', organization_id: id }
      end
    end
  end
end
