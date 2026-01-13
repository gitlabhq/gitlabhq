# frozen_string_literal: true

module Namespaces
  module Stateful
    extend ActiveSupport::Concern

    STATES = {
      ancestor_inherited: nil, # nil means this namespace inherits behavior from ancestors.
      archived: 1,
      deletion_scheduled: 2,
      creation_in_progress: 3,
      deletion_in_progress: 4,
      transfer_in_progress: 5,
      maintenance: 6
    }.with_indifferent_access.freeze

    included do
      include TransitionContext
      include StateQuerying
      include TransitionCallbacks
      include StatePreservation
      include TransitionValidation
      include TransitionLogging

      # TODO: Remove `transition ancestor_inherited:` after backfills are complete https://gitlab.com/groups/gitlab-org/-/epics/17956
      state_machine :state, initial: :ancestor_inherited do
        STATES.each_key do |state_name|
          state state_name.to_sym, value: STATES[state_name]
        end

        before_transition :validate_ancestors_state
        before_transition :handle_state_preservation
        before_transition :update_state_metadata
        before_transition on: :schedule_deletion, do: :ensure_transition_user
        before_transition on: :schedule_deletion, do: :set_deletion_schedule_data
        before_transition on: :cancel_deletion, do: :clear_deletion_schedule_data

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

        after_transition :log_transition

        after_failure :update_state_metadata_on_failure
        after_failure :log_transition_failure
      end
    end
  end
end
