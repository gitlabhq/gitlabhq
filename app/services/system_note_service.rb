# frozen_string_literal: true

# SystemNoteService
#
# Used for creating system notes (e.g., when a user references a merge request
# from an issue, an issue's assignee changes, an issue is closed, etc.)
module SystemNoteService
  extend self

  # Called when commits are added to a Merge Request
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

  def change_milestone(noteable, project, author, milestone)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).change_milestone(milestone)
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
    body = due_date ? "changed due date to #{due_date.to_s(:long)}" : 'removed due date'

    create_note(NoteSummary.new(noteable, project, author, body, action: 'due_date'))
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
    parsed_time = Gitlab::TimeTrackingFormatter.output(noteable.time_estimate)
    body = if noteable.time_estimate == 0
             "removed time estimate"
           else
             "changed time estimate to #{parsed_time}"
           end

    create_note(NoteSummary.new(noteable, project, author, body, action: 'time_tracking'))
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
    time_spent = noteable.time_spent

    if time_spent == :reset
      body = "removed time spent"
    else
      spent_at = noteable.spent_at
      parsed_time = Gitlab::TimeTrackingFormatter.output(time_spent.abs)
      action = time_spent > 0 ? 'added' : 'subtracted'

      text_parts = ["#{action} #{parsed_time} of time spent"]
      text_parts << "at #{spent_at}" if spent_at
      body = text_parts.join(' ')
    end

    create_note(NoteSummary.new(noteable, project, author, body, action: 'time_tracking'))
  end

  def change_status(noteable, project, author, status, source = nil)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).change_status(status, source)
  end

  # Called when 'merge when pipeline succeeds' is executed
  def merge_when_pipeline_succeeds(noteable, project, author, sha)
    body = "enabled an automatic merge when the pipeline for #{sha} succeeds"

    create_note(NoteSummary.new(noteable, project, author, body, action: 'merge'))
  end

  # Called when 'merge when pipeline succeeds' is canceled
  def cancel_merge_when_pipeline_succeeds(noteable, project, author)
    body = 'canceled the automatic merge'

    create_note(NoteSummary.new(noteable, project, author, body, action: 'merge'))
  end

  # Called when 'merge when pipeline succeeds' is aborted
  def abort_merge_when_pipeline_succeeds(noteable, project, author, reason)
    body = "aborted the automatic merge because #{reason}"

    ##
    # TODO: Abort message should be sent by the system, not a particular user.
    # See https://gitlab.com/gitlab-org/gitlab-foss/issues/63187.
    create_note(NoteSummary.new(noteable, project, author, body, action: 'merge'))
  end

  def handle_merge_request_wip(noteable, project, author)
    prefix = noteable.work_in_progress? ? "marked" : "unmarked"

    body = "#{prefix} as a **Work In Progress**"

    create_note(NoteSummary.new(noteable, project, author, body, action: 'title'))
  end

  def add_merge_request_wip_from_commit(noteable, project, author, commit)
    body = "marked as a **Work In Progress** from #{commit.to_reference(project)}"

    create_note(NoteSummary.new(noteable, project, author, body, action: 'title'))
  end

  def resolve_all_discussions(merge_request, project, author)
    body = "resolved all threads"

    create_note(NoteSummary.new(merge_request, project, author, body, action: 'discussion'))
  end

  def discussion_continued_in_issue(discussion, project, author, issue)
    body = "created #{issue.to_reference} to continue this discussion"
    note_attributes = discussion.reply_attributes.merge(project: project, author: author, note: body)

    note = Note.create(note_attributes.merge(system: true, created_at: issue.system_note_timestamp))
    note.system_note_metadata = SystemNoteMetadata.new(action: 'discussion')

    note
  end

  def diff_discussion_outdated(discussion, project, author, change_position)
    merge_request = discussion.noteable
    diff_refs = change_position.diff_refs
    version_index = merge_request.merge_request_diffs.viewable.count
    position_on_text = change_position.on_text?
    text_parts = ["changed this #{position_on_text ? 'line' : 'file'} in"]

    if version_params = merge_request.version_params_for(diff_refs)
      repository = project.repository
      anchor = position_on_text ? change_position.line_code(repository) : change_position.file_hash
      url = url_helpers.diffs_project_merge_request_path(project, merge_request, version_params.merge(anchor: anchor))

      text_parts << "[version #{version_index} of the diff](#{url})"
    else
      text_parts << "version #{version_index} of the diff"
    end

    body = text_parts.join(' ')
    note_attributes = discussion.reply_attributes.merge(project: project, author: author, note: body)

    note = Note.create(note_attributes.merge(system: true))
    note.system_note_metadata = SystemNoteMetadata.new(action: 'outdated')

    note
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
  # old_branch  - old branch name
  # new_branch  - new branch name
  #
  # Example Note text:
  #
  #   "changed target branch from `Old` to `New`"
  #
  # Returns the created Note object
  def change_branch(noteable, project, author, branch_type, old_branch, new_branch)
    body = "changed #{branch_type} branch from `#{old_branch}` to `#{new_branch}`"

    create_note(NoteSummary.new(noteable, project, author, body, action: 'branch'))
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
    verb =
      if presence == :add
        'restored'
      else
        'deleted'
      end

    body = "#{verb} #{branch_type} branch `#{branch}`"

    create_note(NoteSummary.new(noteable, project, author, body, action: 'branch'))
  end

  # Called when a branch is created from the 'new branch' button on a issue
  # Example note text:
  #
  #   "created branch `201-issue-branch-button`"
  def new_issue_branch(issue, project, author, branch, branch_project: nil)
    branch_project ||= project
    link = url_helpers.project_compare_path(branch_project, from: branch_project.default_branch, to: branch)

    body = "created branch [`#{branch}`](#{link}) to address this issue"

    create_note(NoteSummary.new(issue, project, author, body, action: 'branch'))
  end

  def new_merge_request(issue, project, author, merge_request)
    body = "created merge request #{merge_request.to_reference(project)} to address this issue"

    create_note(NoteSummary.new(issue, project, author, body, action: 'merge'))
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

  def mark_duplicate_issue(noteable, project, author, canonical_issue)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).mark_duplicate_issue(canonical_issue)
  end

  def mark_canonical_issue_of_duplicate(noteable, project, author, duplicate_issue)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).mark_canonical_issue_of_duplicate(duplicate_issue)
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

  private

  def create_note(note_summary)
    note = Note.create(note_summary.note.merge(system: true))
    note.system_note_metadata = SystemNoteMetadata.new(note_summary.metadata) if note_summary.metadata?

    note
  end

  def url_helpers
    @url_helpers ||= Gitlab::Routing.url_helpers
  end

  def content_tag(*args)
    ActionController::Base.helpers.content_tag(*args)
  end
end

SystemNoteService.prepend_if_ee('EE::SystemNoteService')
