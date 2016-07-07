# SystemNoteService
#
# Used for creating system notes (e.g., when a user references a merge request
# from an issue, an issue's assignee changes, an issue is closed, etc.)
class SystemNoteService
  # Called when commits are added to a Merge Request
  #
  # noteable         - Noteable object
  # project          - Project owning noteable
  # author           - User performing the change
  # new_commits      - Array of Commits added since last push
  # existing_commits - Array of Commits added in a previous push
  # oldrev           - Optional String SHA of a previous Commit
  #
  # See new_commit_summary and existing_commit_summary.
  #
  # Returns the created Note object
  def self.add_commits(noteable, project, author, new_commits, existing_commits = [], oldrev = nil)
    total_count  = new_commits.length + existing_commits.length
    commits_text = "#{total_count} commit".pluralize(total_count)

    body = "Added #{commits_text}:\n\n"
    body << existing_commit_summary(noteable, existing_commits, oldrev)
    body << new_commit_summary(new_commits).join("\n")

    create_note(noteable: noteable, project: project, author: author, note: body)
  end

  # Called when the assignee of a Noteable is changed or removed
  #
  # noteable - Noteable object
  # project  - Project owning noteable
  # author   - User performing the change
  # assignee - User being assigned, or nil
  #
  # Example Note text:
  #
  #   "Assignee removed"
  #
  #   "Reassigned to @rspeicher"
  #
  # Returns the created Note object
  def self.change_assignee(noteable, project, author, assignee)
    body = assignee.nil? ? 'Assignee removed' : "Reassigned to #{assignee.to_reference}"

    create_note(noteable: noteable, project: project, author: author, note: body)
  end

  # Called when one or more labels on a Noteable are added and/or removed
  #
  # noteable       - Noteable object
  # project        - Project owning noteable
  # author         - User performing the change
  # added_labels   - Array of Labels added
  # removed_labels - Array of Labels removed
  #
  # Example Note text:
  #
  #   "Added ~1 and removed ~2 ~3 labels"
  #
  #   "Added ~4 label"
  #
  #   "Removed ~5 label"
  #
  # Returns the created Note object
  def self.change_label(noteable, project, author, added_labels, removed_labels)
    labels_count = added_labels.count + removed_labels.count

    references     = ->(label) { label.to_reference(format: :id) }
    added_labels   = added_labels.map(&references).join(' ')
    removed_labels = removed_labels.map(&references).join(' ')

    body = ''

    if added_labels.present?
      body << "added #{added_labels}"
      body << ' and ' if removed_labels.present?
    end

    if removed_labels.present?
      body << "removed #{removed_labels}"
    end

    body << ' ' << 'label'.pluralize(labels_count)
    body = body.capitalize

    create_note(noteable: noteable, project: project, author: author, note: body)
  end

  # Called when the milestone of a Noteable is changed
  #
  # noteable  - Noteable object
  # project   - Project owning noteable
  # author    - User performing the change
  # milestone - Milestone being assigned, or nil
  #
  # Example Note text:
  #
  #   "Milestone removed"
  #
  #   "Miletone changed to 7.11"
  #
  # Returns the created Note object
  def self.change_milestone(noteable, project, author, milestone)
    body = 'Milestone '
    body += milestone.nil? ? 'removed' : "changed to #{milestone.to_reference(project)}"

    create_note(noteable: noteable, project: project, author: author, note: body)
  end

  # Called when the status of a Noteable is changed
  #
  # noteable - Noteable object
  # project  - Project owning noteable
  # author   - User performing the change
  # status   - String status
  # source   - Mentionable performing the change, or nil
  #
  # Example Note text:
  #
  #   "Status changed to merged"
  #
  #   "Status changed to closed by bc17db76"
  #
  # Returns the created Note object
  def self.change_status(noteable, project, author, status, source)
    body = "Status changed to #{status}"
    body << " by #{source.gfm_reference(project)}" if source

    create_note(noteable: noteable, project: project, author: author, note: body)
  end

  # Called when 'merge when build succeeds' is executed
  def self.merge_when_build_succeeds(noteable, project, author, last_commit)
    body = "Enabled an automatic merge when the build for #{last_commit.to_reference(project)} succeeds"

    create_note(noteable: noteable, project: project, author: author, note: body)
  end

  # Called when 'merge when build succeeds' is canceled
  def self.cancel_merge_when_build_succeeds(noteable, project, author)
    body = 'Canceled the automatic merge'

    create_note(noteable: noteable, project: project, author: author, note: body)
  end

  def self.remove_merge_request_wip(noteable, project, author)
    body = 'Unmarked this merge request as a Work In Progress'

    create_note(noteable: noteable, project: project, author: author, note: body)
  end

  def self.add_merge_request_wip(noteable, project, author)
    body = 'Marked this merge request as a **Work In Progress**'

    create_note(noteable: noteable, project: project, author: author, note: body)
  end

  # Called when the title of a Noteable is changed
  #
  # noteable  - Noteable object that responds to `title`
  # project   - Project owning noteable
  # author    - User performing the change
  # old_title - Previous String title
  #
  # Example Note text:
  #
  #   "Title changed from **Old** to **New**"
  #
  # Returns the created Note object
  def self.change_title(noteable, project, author, old_title)
    new_title = noteable.title.dup

    old_diffs, new_diffs = Gitlab::Diff::InlineDiff.new(old_title, new_title).inline_diffs

    marked_old_title = Gitlab::Diff::InlineDiffMarker.new(old_title).mark(old_diffs, mode: :deletion, markdown: true)
    marked_new_title = Gitlab::Diff::InlineDiffMarker.new(new_title).mark(new_diffs, mode: :addition, markdown: true)

    body = "Changed title: **#{marked_old_title}** → **#{marked_new_title}**"
    create_note(noteable: noteable, project: project, author: author, note: body)
  end

  # Called when the confidentiality changes
  #
  # issue   - Issue object
  # project - Project owning the issue
  # author  - User performing the change
  #
  # Example Note text:
  #
  # "Made the issue confidential"
  #
  # Returns the created Note object
  def self.change_issue_confidentiality(issue, project, author)
    body = issue.confidential ? 'Made the issue confidential' : 'Made the issue visible'
    create_note(noteable: issue, project: project, author: author, note: body)
  end

  # Called when a branch in Noteable is changed
  #
  # noteable    - Noteable object
  # project     - Project owning noteable
  # author      - User performing the change
  # branch_type - 'source' or 'target'
  # old_branch  - old branch name
  # new_branch  - new branch nmae
  #
  # Example Note text:
  #
  #   "Target branch changed from `Old` to `New`"
  #
  # Returns the created Note object
  def self.change_branch(noteable, project, author, branch_type, old_branch, new_branch)
    body = "#{branch_type} branch changed from `#{old_branch}` to `#{new_branch}`".capitalize
    create_note(noteable: noteable, project: project, author: author, note: body)
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
  #   "Restored target branch `feature`"
  #
  # Returns the created Note object
  def self.change_branch_presence(noteable, project, author, branch_type, branch, presence)
    verb =
      if presence == :add
        'restored'
      else
        'deleted'
      end

    body = "#{verb} #{branch_type.to_s} branch `#{branch}`".capitalize
    create_note(noteable: noteable, project: project, author: author, note: body)
  end

  # Called when a branch is created from the 'new branch' button on a issue
  # Example note text:
  #
  #   "Started branch `201-issue-branch-button`"
  def self.new_issue_branch(issue, project, author, branch)
    h = Gitlab::Routing.url_helpers
    link = h.namespace_project_compare_url(project.namespace, project, from: project.default_branch, to: branch)

    body = "Started branch [`#{branch}`](#{link})"
    create_note(noteable: issue, project: project, author: author, note: body)
  end

  # Called when a Mentionable references a Noteable
  #
  # noteable  - Noteable object being referenced
  # mentioner - Mentionable object
  # author    - User performing the reference
  #
  # Example Note text:
  #
  #   "mentioned in #1"
  #
  #   "mentioned in !2"
  #
  #   "mentioned in 54f7727c"
  #
  # See cross_reference_note_content.
  #
  # Returns the created Note object
  def self.cross_reference(noteable, mentioner, author)
    return if cross_reference_disallowed?(noteable, mentioner)

    gfm_reference = mentioner.gfm_reference(noteable.project)

    note_options = {
      project: noteable.project,
      author:  author,
      note:    cross_reference_note_content(gfm_reference)
    }

    if noteable.kind_of?(Commit)
      note_options.merge!(noteable_type: 'Commit', commit_id: noteable.id)
    else
      note_options.merge!(noteable: noteable)
    end

    if noteable.is_a?(ExternalIssue)
      noteable.project.issues_tracker.create_cross_reference_note(noteable, mentioner, author)
    else
      create_note(note_options)
    end
  end

  def self.cross_reference?(note_text)
    note_text.start_with?(cross_reference_note_prefix)
  end

  # Check if a cross-reference is disallowed
  #
  # This method prevents adding a "mentioned in !1" note on every single commit
  # in a merge request. Additionally, it prevents the creation of references to
  # external issues (which would fail).
  #
  # noteable  - Noteable object being referenced
  # mentioner - Mentionable object
  #
  # Returns Boolean
  def self.cross_reference_disallowed?(noteable, mentioner)
    return true if noteable.is_a?(ExternalIssue) && !noteable.project.jira_tracker_active?
    return false unless mentioner.is_a?(MergeRequest)
    return false unless noteable.is_a?(Commit)

    mentioner.commits.include?(noteable)
  end

  # Check if a cross reference to a noteable from a mentioner already exists
  #
  # This method is used to prevent multiple notes being created for a mention
  # when a issue is updated, for example. The method also calls notes_for_mentioner
  # to check if the mentioner is a commit, and return matches only on commit hash
  # instead of project + commit, to avoid repeated mentions from forks.
  #
  # noteable  - Noteable object being referenced
  # mentioner - Mentionable object
  #
  # Returns Boolean

  def self.cross_reference_exists?(noteable, mentioner)
    # Initial scope should be system notes of this noteable type
    notes = Note.system.where(noteable_type: noteable.class)

    if noteable.is_a?(Commit)
      # Commits have non-integer IDs, so they're stored in `commit_id`
      notes = notes.where(commit_id: noteable.id)
    else
      notes = notes.where(noteable_id: noteable.id)
    end

    notes_for_mentioner(mentioner, noteable, notes).count > 0
  end

  # Called when the merge request is approved by user
  #
  # noteable - Noteable object
  # user     - User performing approve
  #
  # Example Note text:
  #
  #   "Approved this merge request"
  #
  # Returns the created Note object
  def self.approve_mr(noteable, user)
    body = "Approved this merge request"

    create_note(noteable: noteable, project: noteable.project, author: user, note: body)
  end

  private

  def self.notes_for_mentioner(mentioner, noteable, notes)
    if mentioner.is_a?(Commit)
      notes.where('note LIKE ?', "#{cross_reference_note_prefix}%#{mentioner.to_reference(nil)}")
    else
      gfm_reference = mentioner.gfm_reference(noteable.project)
      notes.where(note: cross_reference_note_content(gfm_reference))
    end
  end

  def self.create_note(args = {})
    Note.create(args.merge(system: true))
  end

  def self.cross_reference_note_prefix
    'mentioned in '
  end

  def self.cross_reference_note_content(gfm_reference)
    "#{cross_reference_note_prefix}#{gfm_reference}"
  end

  # Build an Array of lines detailing each commit added in a merge request
  #
  # new_commits - Array of new Commit objects
  #
  # Returns an Array of Strings
  def self.new_commit_summary(new_commits)
    new_commits.collect do |commit|
      "* #{commit.short_id} - #{escape_html(commit.title)}"
    end
  end

  # Build a single line summarizing existing commits being added in a merge
  # request
  #
  # noteable         - MergeRequest object
  # existing_commits - Array of existing Commit objects
  # oldrev           - Optional String SHA of a previous Commit
  #
  # Examples:
  #
  #   "* ea0f8418...2f4426b7 - 24 commits from branch `master`"
  #
  #   "* ea0f8418..4188f0ea - 15 commits from branch `fork:master`"
  #
  #   "* ea0f8418 - 1 commit from branch `feature`"
  #
  # Returns a newline-terminated String
  def self.existing_commit_summary(noteable, existing_commits, oldrev = nil)
    return '' if existing_commits.empty?

    count = existing_commits.size

    commit_ids = if count == 1
                   existing_commits.first.short_id
                 else
                   if oldrev && !Gitlab::Git.blank_ref?(oldrev)
                     "#{Commit.truncate_sha(oldrev)}...#{existing_commits.last.short_id}"
                   else
                     "#{existing_commits.first.short_id}..#{existing_commits.last.short_id}"
                   end
                 end

    commits_text = "#{count} commit".pluralize(count)

    branch = noteable.target_branch
    branch = "#{noteable.target_project_namespace}:#{branch}" if noteable.for_fork?

    "* #{commit_ids} - #{commits_text} from branch `#{branch}`\n"
  end

  # Called when the status of a Task has changed
  #
  # noteable  - Noteable object.
  # project   - Project owning noteable
  # author    - User performing the change
  # new_task  - TaskList::Item object.
  #
  # Example Note text:
  #
  #   "Soandso marked the task Whatever as completed."
  #
  # Returns the created Note object
  def self.change_task_status(noteable, project, author, new_task)
    status_label = new_task.complete? ? Taskable::COMPLETED : Taskable::INCOMPLETE
    body = "Marked the task **#{new_task.source}** as #{status_label}"
    create_note(noteable: noteable, project: project, author: author, note: body)
  end

  # Called when noteable has been moved to another project
  #
  # direction    - symbol, :to or :from
  # noteable     - Noteable object
  # noteable_ref - Referenced noteable
  # author       - User performing the move
  #
  # Example Note text:
  #
  #   "Moved to some_namespace/project_new#11"
  #
  # Returns the created Note object
  def self.noteable_moved(noteable, project, noteable_ref, author, direction:)
    unless [:to, :from].include?(direction)
      raise ArgumentError, "Invalid direction `#{direction}`"
    end

    cross_reference = noteable_ref.to_reference(project)
    body = "Moved #{direction} #{cross_reference}"
    create_note(noteable: noteable, project: project, author: author, note: body)
  end

  def self.escape_html(text)
    Rack::Utils.escape_html(text)
  end
end
