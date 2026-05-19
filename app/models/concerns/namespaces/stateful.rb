# frozen_string_literal: true

module Namespaces
  module Stateful
    extend ActiveSupport::Concern

    included do
      include ::Gitlab::TenantContainerLifecycle::Stateful::TransitionContext
      include TransitionCallbacks
      include StatePreservation
      include TransitionValidation
      include ::Gitlab::TenantContainerLifecycle::Stateful::TransitionLogging
      include StateQuerying

      attribute :state, :integer, limit: 2, default: 0

      enum :state, {
        ancestor_inherited: 0,
        archived: 1,
        deletion_scheduled: 2,
        creation_in_progress: 3,
        deletion_in_progress: 4,
        transfer_in_progress: 5,
        maintenance: 6,
        transfer_scheduled: 7
      }, instance_methods: false

      state_machine :state, initial: :ancestor_inherited do
        state :creation_in_progress
        state :maintenance

        before_transition :validate_ancestors_state
        before_transition :handle_state_preservation
        before_transition :update_state_metadata
        before_transition on: :schedule_deletion, do: :ensure_transition_user
        before_transition on: :schedule_deletion, do: :set_deletion_schedule_data
        before_transition on: :cancel_deletion, do: :clear_deletion_schedule_data
        before_transition on: :schedule_transfer, do: :ensure_transition_user
        before_transition on: :schedule_transfer, do: :set_transfer_schedule_data
        before_transition on: :start_transfer, do: :ensure_transition_user
        before_transition on: :start_transfer, do: :set_transfer_data
        before_transition on: [:complete_transfer, :cancel_transfer], do: :clear_transfer_data
        before_transition on: :reschedule_deletion, do: :set_deletion_error_data

        event :archive do
          transition ancestor_inherited: :archived
        end

        event :unarchive do
          transition archived: :ancestor_inherited
          transition ancestor_inherited: :ancestor_inherited,
            unless: :remove_ancestor_inherited_transitions?
        end

        event :schedule_deletion do
          transition %i[ancestor_inherited archived] => :deletion_scheduled
        end

        event :start_deletion do
          transition %i[ancestor_inherited archived deletion_scheduled] => :deletion_in_progress
        end

        event :reschedule_deletion do
          transition deletion_in_progress: :ancestor_inherited,
            if: :restore_to_ancestor_inherited_on_reschedule_deletion?
          transition deletion_in_progress: :archived, if: :restore_to_archived_on_reschedule_deletion?
          transition deletion_in_progress: :deletion_scheduled,
            if: :restore_to_deletion_scheduled_on_reschedule_deletion?
          transition deletion_in_progress: :deletion_scheduled
          transition ancestor_inherited: :deletion_scheduled
        end

        event :cancel_deletion do
          transition %i[deletion_scheduled deletion_in_progress] => :archived,
            if: :restore_to_archived_on_cancel_deletion?
          transition %i[deletion_scheduled deletion_in_progress] => :ancestor_inherited
          transition ancestor_inherited: :archived, if: :restore_to_archived_on_cancel_deletion?
          transition ancestor_inherited: :ancestor_inherited,
            unless: :remove_ancestor_inherited_transitions?
        end

        event :schedule_transfer do
          transition %i[ancestor_inherited archived] => :transfer_scheduled
        end

        event :start_transfer do
          transition transfer_scheduled: :transfer_in_progress
        end

        event :complete_transfer do
          transition transfer_in_progress: :archived,
            if: :restore_to_archived_on_complete_transfer?
          transition transfer_in_progress: :ancestor_inherited
        end

        event :cancel_transfer do
          transition %i[transfer_scheduled transfer_in_progress] => :archived,
            if: :restore_to_archived_on_cancel_transfer?
          transition %i[transfer_scheduled transfer_in_progress] => :ancestor_inherited
        end

        after_transition :log_transition
        after_transition to: :archived, do: :invalidate_namespace_descendants_cache
        after_transition from: :archived, do: :invalidate_namespace_descendants_cache

        after_failure :update_state_metadata_on_failure
        after_failure :log_transition_failure
      end

      private

      def remove_ancestor_inherited_transitions?
        false
      end

      def stateful_detail
        namespace_details
      end

      def invalidate_namespace_descendants_cache
        return if is_a?(Namespaces::UserNamespace)

        if is_a?(Namespaces::ProjectNamespace)
          Namespaces::Descendants.expire_for([parent_id])
        else
          Namespaces::Descendants.expire_recursive_for(self)
        end
      end

      def stateful_log_metadata
        { message: 'Namespace state transition', namespace_id: id }
      end
    end
  end
end
