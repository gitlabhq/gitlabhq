# frozen_string_literal: true

# A module for deletable models. It provides methods to describe the deletion status of a model.
# Support for delayed deletion is provided.
#
# The #self_deletion_in_progress? method needs to be defined.
# The #delayed_deletion_available? method can be overriden.
# The #delayed_deletion_configured? method can be overriden.
# The #all_scheduled_for_deletion_in_hierarchy_chain method can be overriden.
module DeletableNamespace
  extend ActiveSupport::Concern

  # Models need to define this method, usually based on the value of a database attribute
  def self_deletion_in_progress?
    raise NotImplementedError
  end

  # Returns the date when the scheduled deletion was created.
  # For now, delayed deletion isn't supported in FOSS.
  def self_deletion_scheduled_deletion_created_on
    marked_for_deletion_on if respond_to?(:marked_for_deletion_on)
  end

  # Returns true if the record is scheduled for deletion.
  # For now, delayed deletion isn't supported in FOSS.
  def self_deletion_scheduled?
    self_deletion_scheduled_deletion_created_on.present?
  end
  # TODO: Replace calls to #marked_for_deletion? with #self_deletion_scheduled?
  alias_method :marked_for_deletion?, :self_deletion_scheduled?

  # Returns true if the delayed deletion feature is available for the current record.
  # Can be overidden.
  def delayed_deletion_available?
    respond_to?(:licensed_feature_available?) &&
      licensed_feature_available?(:adjourned_deletion_for_projects_and_groups)
  end

  # Returns true if the delayed deletion feature is configured.
  # Can be overidden.
  def delayed_deletion_configured?
    ::Gitlab::CurrentSettings.deletion_adjourned_period > 0
  end

  # Returns an array of records that are scheduled for deletion in the hierarchy chain of the current record.
  # For now, delayed deletion isn't supported in FOSS.
  # This method can be overriden in EE models.
  def all_scheduled_for_deletion_in_hierarchy_chain
    []
  end

  # Returns the first record that's secheduled for deletion in self's ancestors chain (including itself).
  # For now, delayed deletion isn't supported in FOSS.
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

  def delayed_deletion_ready?
    delayed_deletion_available? && delayed_deletion_configured?
  end
  # TODO: Replace calls to #adjourned_deletion? with #delayed_deletion_ready?
  alias_method :adjourned_deletion?, :delayed_deletion_ready?
end
