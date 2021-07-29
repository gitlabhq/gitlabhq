# frozen_string_literal: true

# This module handles backward compatibility for import/export of merge requests after
# multiple assignees feature was introduced. Also, it handles the scenarios where
# the #26496 background migration hasn't finished yet.
# Ideally, most of this code should be removed at #59457.
module DeprecatedAssignee
  extend ActiveSupport::Concern

  def assignee_ids=(ids)
    nullify_deprecated_assignee
    super
  end

  def assignees=(users)
    nullify_deprecated_assignee
    super
  end

  def assignee_id=(id)
    self.assignee_ids = Array(id)
  end

  def assignee=(user)
    self.assignees = Array(user)
  end

  def assignee
    assignees.first
  end

  def assignee_id
    assignee_ids.first
  end

  def assignee_ids
    if Gitlab::Database.main.read_only? && pending_assignees_population?
      return Array(deprecated_assignee_id)
    end

    update_assignees_relation
    super
  end

  def assignees
    if Gitlab::Database.main.read_only? && pending_assignees_population?
      return User.where(id: deprecated_assignee_id)
    end

    update_assignees_relation
    super
  end

  private

  # This will make the background migration process quicker (#26496) as it'll have less
  # assignee_id rows to look through.
  def nullify_deprecated_assignee
    return unless persisted? && Gitlab::Database.main.read_only?

    update_column(:assignee_id, nil)
  end

  # This code should be removed in the clean-up phase of the
  # background migration (#59457).
  def pending_assignees_population?
    persisted? && deprecated_assignee_id && merge_request_assignees.empty?
  end

  # If there's an assignee_id and no relation, it means the background
  # migration at #26496 didn't reach this merge request yet.
  # This code should be removed in the clean-up phase of the
  # background migration (#59457).
  def update_assignees_relation
    if pending_assignees_population?
      transaction do
        merge_request_assignees.create!(user_id: deprecated_assignee_id, merge_request_id: id)
        update_column(:assignee_id, nil)
      end
    end
  end

  def deprecated_assignee_id
    read_attribute(:assignee_id)
  end
end
