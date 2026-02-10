# frozen_string_literal: true

# A module for deletable models. It provides methods to describe the deletion status of a model.
# Support for delayed deletion is provided.
#
# The #self_deletion_in_progress? method needs to be defined.
# The #ancestors_scheduled_for_deletion method can be overriden.
module Namespaces
  module AdjournedDeletable
    extend ActiveSupport::Concern

    # Models need to define this method, usually based on the value of a database attribute
    def self_deletion_in_progress?
      deletion_in_progress?
    end

    # Returns an array of the record's ancestors that are scheduled for deletion.
    # This method can be overriden.
    def ancestors_scheduled_for_deletion
      []
    end
    private :ancestors_scheduled_for_deletion

    # Returns the date when the scheduled deletion was created.
    def self_deletion_scheduled_deletion_created_on
      self_deletion_scheduled_deletion_created_on_legacy || deletion_schedule_from_state_metadata
    end

    # Returns true if the record is scheduled for deletion.
    def self_deletion_scheduled?
      self_deletion_scheduled_deletion_created_on_legacy.present? || deletion_scheduled?
    end

    def ancestor_scheduled_for_deletion?
      ancestors_scheduled_for_deletion.any?
    end

    # Returns the first record that's scheduled for deletion in self's ancestors chain (including itself).
    def first_scheduled_for_deletion_in_hierarchy_chain
      return self if self_deletion_scheduled?

      ancestors_scheduled_for_deletion.first
    end

    # Returns true if the record or any of its ancestors is scheduled for deletion.
    def scheduled_for_deletion_in_hierarchy_chain?
      first_scheduled_for_deletion_in_hierarchy_chain.present?
    end

    # Returns true if the record or any of its ancestors is being deleted or scheduled for deletion.
    def deletion_in_progress_or_scheduled_in_hierarchy_chain?
      self_deletion_in_progress? || scheduled_for_deletion_in_hierarchy_chain?
    end

    def deletion_adjourned_period
      ::Gitlab::CurrentSettings.deletion_adjourned_period
    end

    private

    def deletion_schedule_from_state_metadata
      return unless try(:namespace_details)

      deletion_schedule = namespace_details.state_metadata['deletion_scheduled_at']
      Time.zone.parse(deletion_schedule) if deletion_schedule.present?
    end

    def self_deletion_scheduled_deletion_created_on_legacy
      try(:marked_for_deletion_on)
    end
  end
end
