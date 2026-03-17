# frozen_string_literal: true

module Namespaces
  module Stateful
    extend ActiveSupport::Concern

    included do
      include TransitionContext
      include TransitionCallbacks
      include StatePreservation
      include TransitionValidation
      include TransitionLogging

      attribute :state, :integer, limit: 2, default: 0

      enum :state, {
        ancestor_inherited: 0,
        archived: 1,
        deletion_scheduled: 2,
        creation_in_progress: 3,
        deletion_in_progress: 4,
        transfer_in_progress: 5,
        maintenance: 6
      }, instance_methods: false

      # TODO: We're overriding the scopes defined by `enum :state` in `StateQuerying`.
      # Move with the above include statements above after BBM is finalized
      # https://gitlab.com/gitlab-org/gitlab/-/issues/588431 and remove the scopes in `StateQuerying`.
      include StateQuerying

      # During migration, both NULL and 0 represent ancestor_inherited in the database.
      # Override the state reader so that NULL is treated as ancestor_inherited (value 0).
      # TODO: Remove after NULL->0 backfill is complete https://gitlab.com/gitlab-org/gitlab/-/issues/588431
      def state(...)
        super || 'ancestor_inherited'
      end

      # TODO: Remove `transition ancestor_inherited:` after backfills are complete https://gitlab.com/groups/gitlab-org/-/epics/17956
      state_machine :state, initial: :ancestor_inherited do
        state :creation_in_progress
        state :maintenance

        before_transition :validate_ancestors_state
        before_transition :handle_state_preservation
        before_transition :update_state_metadata
        before_transition on: :schedule_deletion, do: :ensure_transition_user
        before_transition on: :schedule_deletion, do: :set_deletion_schedule_data
        before_transition on: :cancel_deletion, do: :clear_deletion_schedule_data
        before_transition on: :start_transfer, do: :ensure_transition_user
        before_transition on: :start_transfer, do: :set_transfer_data
        before_transition on: [:complete_transfer, :cancel_transfer], do: :clear_transfer_data

        event :archive do
          transition ancestor_inherited: :archived
        end

        event :unarchive do
          transition archived: :ancestor_inherited
          transition ancestor_inherited: :ancestor_inherited
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
          transition ancestor_inherited: :ancestor_inherited
        end

        event :start_transfer do
          transition %i[ancestor_inherited archived] => :transfer_in_progress
        end

        event :complete_transfer do
          transition transfer_in_progress: :archived,
            if: :restore_to_archived_on_complete_transfer?
          transition transfer_in_progress: :ancestor_inherited
        end

        event :cancel_transfer do
          transition transfer_in_progress: :archived,
            if: :restore_to_archived_on_cancel_transfer?
          transition transfer_in_progress: :ancestor_inherited
        end

        after_transition :log_transition

        after_failure :update_state_metadata_on_failure
        after_failure :log_transition_failure
      end
    end
  end
end
