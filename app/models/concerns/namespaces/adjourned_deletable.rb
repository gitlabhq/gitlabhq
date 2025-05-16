# frozen_string_literal: true

# A module for deletable models. It provides methods to describe the deletion status of a model.
# Support for delayed deletion is provided.
#
# The #self_deletion_in_progress? method needs to be defined.
# The #all_scheduled_for_deletion_in_hierarchy_chain method can be overriden.
module Namespaces
  module AdjournedDeletable
    extend ActiveSupport::Concern

    # Models need to define this method, usually based on the value of a database attribute
    def self_deletion_in_progress?
      raise NotImplementedError
    end

    # Returns an array of records that are scheduled for deletion in the hierarchy chain of the current record.
    # This method can be overriden.
    def all_scheduled_for_deletion_in_hierarchy_chain
      []
    end
    private :all_scheduled_for_deletion_in_hierarchy_chain

    def delayed_deletion_ready?
      deletion_adjourned_period > 0
    end
    # TODO: Replace calls to #adjourned_deletion? with #delayed_deletion_ready?
    # TODO: Replace calls to #delayed_deletion_configured? with #delayed_deletion_ready?
    # TODO: Replace calls to #adjourned_deletion_configured? with #delayed_deletion_ready?
    alias_method :adjourned_deletion?, :delayed_deletion_ready?
    alias_method :delayed_deletion_configured?, :delayed_deletion_ready?
    alias_method :adjourned_deletion_configured?, :delayed_deletion_ready?

    # Returns the date when the scheduled deletion was created.
    def self_deletion_scheduled_deletion_created_on
      marked_for_deletion_on if respond_to?(:marked_for_deletion_on)
    end

    # Returns true if the record is scheduled for deletion.
    def self_deletion_scheduled?
      self_deletion_scheduled_deletion_created_on.present?
    end
    # TODO: Replace calls to #marked_for_deletion? with #self_deletion_scheduled?
    alias_method :marked_for_deletion?, :self_deletion_scheduled?

    # Returns the first record that's scheduled for deletion in self's ancestors chain (including itself).
    def first_scheduled_for_deletion_in_hierarchy_chain
      return unless delayed_deletion_ready?
      return self if self_deletion_scheduled?

      all_scheduled_for_deletion_in_hierarchy_chain.first
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
  end
end
