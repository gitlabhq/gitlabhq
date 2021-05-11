# frozen_string_literal: true

# SystemNoteService
#
# Used for creating system notes (e.g., when a user references a merge request
# from an issue, an issue's assignee changes, an issue is closed, etc.)
module SystemNoteService
  extend self

  # Called when commits are added to a merge request
  #
  # noteable         - Noteable object
  # project          - Project owning noteable
  # author           - User performing the change
  # new_commits      - Array of Commits added since last push
  # existing_commits - Array of Commits added in a previous push
  # oldrev           - Optional String SHA of a previous Commit
  #
  # Returns the created Note object
  def add_commits(noteable, project, author, new_commits, existing_commits = [], oldrev = nil)
    ::SystemNotes::CommitService.new(noteable: noteable, project: project, author: author).add_commits(new_commits, existing_commits, oldrev)
  end

  # Called when a commit was tagged
  #
  # noteable  - Noteable object
  # project   - Project owning noteable
  # author    - User performing the tag
  # tag_name  - The created tag name
  #
  # Returns the created Note object
  def tag_commit(noteable, project, author, tag_name)
    ::SystemNotes::CommitService.new(noteable: noteable, project: project, author: author).tag_commit(tag_name)
  end

  def change_assignee(noteable, project, author, assignee)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).change_assignee(assignee)
  end

  def change_issuable_assignees(issuable, project, author, old_assignees)
    ::SystemNotes::IssuablesService.new(noteable: issuable, project: project, author: author).change_issuable_assignees(old_assignees)
  end

  def change_issuable_reviewers(issuable, project, author, old_reviewers)
    ::SystemNotes::IssuablesService.new(noteable: issuable, project: project, author: author).change_issuable_reviewers(old_reviewers)
  end

  def relate_issue(noteable, noteable_ref, user)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: noteable.project, author: user).relate_issue(noteable_ref)
  end

  def unrelate_issue(noteable, noteable_ref, user)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: noteable.project, author: user).unrelate_issue(noteable_ref)
  end

  # Called when the due_date of a Noteable is changed
  #
  # noteable  - Noteable object
  # project   - Project owning noteable
  # author    - User performing the change
  # due_date  - Due date being assigned, or nil
  #
  # Example Note text:
  #
  #   "removed due date"
  #
  #   "changed due date to September 20, 2018"
  #
  # Returns the created Note object
  def change_due_date(noteable, project, author, due_date)
    ::SystemNotes::TimeTrackingService.new(noteable: noteable, project: project, author: author).change_due_date(due_date)
  end

  # Called when the estimated time of a Noteable is changed
  #
  # noteable      - Noteable object
  # project       - Project owning noteable
  # author        - User performing the change
  # time_estimate - Estimated time
  #
  # Example Note text:
  #
  #   "removed time estimate"
  #
  #   "changed time estimate to 3d 5h"
  #
  # Returns the created Note object
  def change_time_estimate(noteable, project, author)
    ::SystemNotes::TimeTrackingService.new(noteable: noteable, project: project, author: author).change_time_estimate
  end

  # Called when the spent time of a Noteable is changed
  #
  # noteable   - Noteable object
  # project    - Project owning noteable
  # author     - User performing the change
  # time_spent - Spent time
  #
  # Example Note text:
  #
  #   "removed time spent"
  #
  #   "added 2h 30m of time spent"
  #
  # Returns the created Note object
  def change_time_spent(noteable, project, author)
    ::SystemNotes::TimeTrackingService.new(noteable: noteable, project: project, author: author).change_time_spent
  end

  def close_after_error_tracking_resolve(issue, project, author)
    ::SystemNotes::IssuablesService.new(noteable: issue, project: project, author: author).close_after_error_tracking_resolve
  end

  def change_status(noteable, project, author, status, source = nil)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).change_status(status, source)
  end

  # Called when 'merge when pipeline succeeds' is executed
  def merge_when_pipeline_succeeds(noteable, project, author, sha)
    ::SystemNotes::MergeRequestsService.new(noteable: noteable, project: project, author: author).merge_when_pipeline_succeeds(sha)
  end

  # Called when 'merge when pipeline succeeds' is canceled
  def cancel_merge_when_pipeline_succeeds(noteable, project, author)
    ::SystemNotes::MergeRequestsService.new(noteable: noteable, project: project, author: author).cancel_merge_when_pipeline_succeeds
  end

  # Called when 'merge when pipeline succeeds' is aborted
  def abort_merge_when_pipeline_succeeds(noteable, project, author, reason)
    ::SystemNotes::MergeRequestsService.new(noteable: noteable, project: project, author: author).abort_merge_when_pipeline_succeeds(reason)
  end

  def handle_merge_request_draft(noteable, project, author)
    ::SystemNotes::MergeRequestsService.new(noteable: noteable, project: project, author: author).handle_merge_request_draft
  end

  def add_merge_request_draft_from_commit(noteable, project, author, commit)
    ::SystemNotes::MergeRequestsService.new(noteable: noteable, project: project, author: author).add_merge_request_draft_from_commit(commit)
  end

  def resolve_all_discussions(merge_request, project, author)
    ::SystemNotes::MergeRequestsService.new(noteable: merge_request, project: project, author: author).resolve_all_discussions
  end

  def discussion_continued_in_issue(discussion, project, author, issue)
    ::SystemNotes::MergeRequestsService.new(project: project, author: author).discussion_continued_in_issue(discussion, issue)
  end

  def diff_discussion_outdated(discussion, project, author, change_position)
    ::SystemNotes::MergeRequestsService.new(project: project, author: author).diff_discussion_outdated(discussion, change_position)
  end

  def change_title(noteable, project, author, old_title)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).change_title(old_title)
  end

  def change_description(noteable, project, author)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).change_description
  end

  def change_issue_confidentiality(issue, project, author)
    ::SystemNotes::IssuablesService.new(noteable: issue, project: project, author: author).change_issue_confidentiality
  end

  # Called when a branch in Noteable is changed
  #
  # noteable    - Noteable object
  # project     - Project owning noteable
  # author      - User performing the change
  # branch_type - 'source' or 'target'
  # event_type  - the source of event: 'update' or 'delete'
  # old_branch  - old branch name
  # new_branch  - new branch name
  #
  # Example Note text is based on event_type:
  #
  #   update: "changed target branch from `Old` to `New`"
  #   delete: "deleted the `Old` branch. This merge request now targets the `New` branch"
  #
  # Returns the created Note object
  def change_branch(noteable, project, author, branch_type, event_type, old_branch, new_branch)
    ::SystemNotes::MergeRequestsService.new(noteable: noteable, project: project, author: author)
      .change_branch(branch_type, event_type, old_branch, new_branch)
  end

  # Called when a branch in Noteable is added or deleted
  #
  # noteable    - Noteable object
  # project     - Project owning noteable
  # author      - User performing the change
  # branch_type - :source or :target
  # branch      - branch name
  # presence    - :add or :delete
  #
  # Example Note text:
  #
  #   "restored target branch `feature`"
  #
  # Returns the created Note object
  def change_branch_presence(noteable, project, author, branch_type, branch, presence)
    ::SystemNotes::MergeRequestsService.new(noteable: noteable, project: project, author: author).change_branch_presence(branch_type, branch, presence)
  end

  # Called when a branch is created from the 'new branch' button on a issue
  # Example note text:
  #
  #   "created branch `201-issue-branch-button`"
  def new_issue_branch(issue, project, author, branch, branch_project: nil)
    ::SystemNotes::MergeRequestsService.new(noteable: issue, project: project, author: author).new_issue_branch(branch, branch_project: branch_project)
  end

  def new_merge_request(issue, project, author, merge_request)
    ::SystemNotes::MergeRequestsService.new(noteable: issue, project: project, author: author).new_merge_request(merge_request)
  end

  def cross_reference(noteable, mentioner, author)
    ::SystemNotes::IssuablesService.new(noteable: noteable, author: author).cross_reference(mentioner)
  end

  def cross_reference_exists?(noteable, mentioner)
    ::SystemNotes::IssuablesService.new(noteable: noteable).cross_reference_exists?(mentioner)
  end

  def change_task_status(noteable, project, author, new_task)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).change_task_status(new_task)
  end

  def noteable_moved(noteable, project, noteable_ref, author, direction:)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).noteable_moved(noteable_ref, direction)
  end

  def noteable_cloned(noteable, project, noteable_ref, author, direction:)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).noteable_cloned(noteable_ref, direction)
  end

  def mark_duplicate_issue(noteable, project, author, canonical_issue)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).mark_duplicate_issue(canonical_issue)
  end

  def mark_canonical_issue_of_duplicate(noteable, project, author, duplicate_issue)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).mark_canonical_issue_of_duplicate(duplicate_issue)
  end

  def add_email_participants(noteable, project, author, body)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).add_email_participants(body)
  end

  def discussion_lock(issuable, author)
    ::SystemNotes::IssuablesService.new(noteable: issuable, project: issuable.project, author: author).discussion_lock
  end

  def cross_reference_disallowed?(noteable, mentioner)
    ::SystemNotes::IssuablesService.new(noteable: noteable).cross_reference_disallowed?(mentioner)
  end

  def zoom_link_added(issue, project, author)
    ::SystemNotes::ZoomService.new(noteable: issue, project: project, author: author).zoom_link_added
  end

  def zoom_link_removed(issue, project, author)
    ::SystemNotes::ZoomService.new(noteable: issue, project: project, author: author).zoom_link_removed
  end

  def auto_resolve_prometheus_alert(noteable, project, author)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).auto_resolve_prometheus_alert
  end

  # Parameters:
  #   - version [DesignManagement::Version]
  #
  # Example Note text:
  #
  #   "added [1 designs](link-to-version)"
  #   "changed [2 designs](link-to-version)"
  #
  # Returns [Array<Note>]: the created Note objects
  def design_version_added(version)
    ::SystemNotes::DesignManagementService.new(noteable: version.issue, project: version.issue.project, author: version.author).design_version_added(version)
  end

  # Called when a new discussion is created on a design
  #
  # discussion_note - DiscussionNote
  #
  # Example Note text:
  #
  #   "started a discussion on screen.png"
  #
  # Returns the created Note object
  def design_discussion_added(discussion_note)
    design = discussion_note.noteable

    ::SystemNotes::DesignManagementService.new(noteable: design.issue, project: design.project, author: discussion_note.author).design_discussion_added(discussion_note)
  end

  # Called when the merge request is approved by user
  #
  # noteable - Noteable object
  # user     - User performing approve
  #
  # Example Note text:
  #
  #   "approved this merge request"
  #
  # Returns the created Note object
  def approve_mr(noteable, user)
    merge_requests_service(noteable, noteable.project, user).approve_mr
  end

  def unapprove_mr(noteable, user)
    merge_requests_service(noteable, noteable.project, user).unapprove_mr
  end

  def change_alert_status(alert, author)
    ::SystemNotes::AlertManagementService.new(noteable: alert, project: alert.project, author: author).change_alert_status(alert)
  end

  def new_alert_issue(alert, issue, author)
    ::SystemNotes::AlertManagementService.new(noteable: alert, project: alert.project, author: author).new_alert_issue(issue)
  end

  def create_new_alert(alert, monitoring_tool)
    ::SystemNotes::AlertManagementService.new(noteable: alert, project: alert.project).create_new_alert(monitoring_tool)
  end

  def change_incident_severity(incident, author)
    ::SystemNotes::IncidentService.new(noteable: incident, project: incident.project, author: author).change_incident_severity
  end

  def log_resolving_alert(alert, monitoring_tool)
    ::SystemNotes::AlertManagementService.new(noteable: alert, project: alert.project).log_resolving_alert(monitoring_tool)
  end

  private

  def merge_requests_service(noteable, project, author)
    ::SystemNotes::MergeRequestsService.new(noteable: noteable, project: project, author: author)
  end
end

SystemNoteService.prepend_mod_with('SystemNoteService')
