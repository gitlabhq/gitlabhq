module AssigneeLiveMigration
  # This method is a part of live migration concept. We need to migrate assignee_id
  # to a separate table issue_assignees
  def migrate_assignee
    if assignee_needs_to_be_migrated?
      Issue.transaction do
        IssueAssignee.create(issue_id: id, user_id: assignee_id)
        update(assignee_id: nil)
      end

      return true
    end

    false
  end

  def assignee_needs_to_be_migrated?
    assignee_id
  end
end
