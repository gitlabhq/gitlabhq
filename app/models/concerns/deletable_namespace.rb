# frozen_string_literal: true

# A module for deletable models. It provides methods to describe the deletion status of a model.
# Support for delayed deletion is provided.
#
# The #self_deletion_in_progress? method needs to be defined.
module DeletableNamespace
  extend ActiveSupport::Concern

  # Models need to define this method, usually based on the value of a database attribute
  def self_deletion_in_progress?
    raise NotImplementedError
  end

  def scheduled_for_deletion_in_hierarchy_chain?; end

  # Returns true if the record or any of its ancestors is being deleted or scheduled for deletion.
  def deletion_in_progress_or_scheduled_in_hierarchy_chain?
    self_deletion_in_progress? || scheduled_for_deletion_in_hierarchy_chain?
  end
end
