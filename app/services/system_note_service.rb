# SystemNoteService
#
# Used for creating system notes (e.g., when a user references a merge request
# from an issue, an issue's assignee changes, an issue is closed, etc.)
#
# All methods creating notes should be named using a singular noun and
# present-tense verb (e.g., "assignee_change" not "assignee_changed",
# "label_change" not "labels_change").
class SystemNoteService
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
  def self.assignee_change(noteable, project, author, assignee)
    body = assignee.nil? ? 'Assignee removed' : "Reassigned to @#{assignee.username}"

    create_note(noteable: noteable, project: project, author: author, note: body)
  end

  # Called when a Mentionable references a Noteable
  #
  # noteable  - Noteable object being referenced
  # mentioner - Mentionable object
  # author    - User performing the reference
  #
  # Example Note text:
  #
  #   "Mentioned in #1"
  #
  #   "Mentioned in !2"
  #
  #   "Mentioned in 54f7727c"
  #
  # See cross_reference_note_content.
  #
  # Returns the created Note object
  def self.cross_reference(noteable, mentioner, author)
    return if cross_reference_disallowed?(noteable, mentioner)

    gfm_reference = mentioner_gfm_ref(noteable, mentioner)

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

    create_note(note_options)
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
  def self.label_change(noteable, project, author, added_labels, removed_labels)
    labels_count = added_labels.count + removed_labels.count

    references     = ->(label) { "~#{label.id}" }
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
    body = "#{body.capitalize}"

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
  def self.milestone_change(noteable, project, author, milestone)
    body = 'Milestone '
    body += milestone.nil? ? 'removed' : "changed to #{milestone.title}"

    create_note(noteable: noteable, project: project, author: author, note: body)
  end

  # Called when commits are added to a Merge Request
  #
  # noteable         - Noteable object
  # project          - Project owning noteable
  # author           - User performing the change
  # new_commits      - Array of Commits added since last push
  # existing_commits - Array of Commits added in a previous push
  # oldrev           - TODO (rspeicher): I have no idea what this actually does
  #
  # See new_commit_summary and existing_commit_summary.
  #
  # Returns the created Note object
  def self.commit_add(noteable, project, author, new_commits, existing_commits = [], oldrev = nil)
    total_count  = new_commits.length + existing_commits.length
    commits_text = "#{total_count} commit".pluralize(total_count)

    body = "Added #{commits_text}:\n\n"
    body << existing_commit_summary(noteable, existing_commits, oldrev)
    body << new_commit_summary(new_commits).join("\n")

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
  def self.status_change(noteable, project, author, status, source)
    body = "Status changed to #{status}"
    body += " by #{source.gfm_reference}" if source

    create_note(noteable: noteable, project: project, author: author, note: body)
  end

  def self.cross_reference?(note_text)
    note_text.start_with?(cross_reference_note_prefix)
  end

  # Determine if cross reference note should be created.
  # eg. mentioning a commit in MR comments which exists inside a MR
  # should not create "mentioned in" note.
  def self.cross_reference_disallowed?(noteable, mentioner)
    if mentioner.kind_of?(MergeRequest)
      mentioner.commits.map(&:id).include? noteable.id
    end
  end

  def self.cross_reference_exists?(noteable, mentioner)
    # Initial scope should be system notes of this noteable type
    notes = Note.system.where(noteable_type: noteable.class)

    if noteable.is_a?(Commit)
      # Commits have non-integer IDs, so they're stored in `commit_id`
      notes = notes.where(commit_id: noteable.id)
    else
      notes = notes.where(noteable_id: noteable.id)
    end

    gfm_reference = mentioner_gfm_ref(noteable, mentioner, true)
    notes = notes.where(note: cross_reference_note_content(gfm_reference))

    notes.count > 0
  end

  private

  def self.create_note(args = {})
    Note.create(args.merge(system: true))
  end

  # Prepend the mentioner's namespaced project path to the GFM reference for
  # cross-project references.  For same-project references, return the
  # unmodified GFM reference.
  def self.mentioner_gfm_ref(noteable, mentioner, cross_reference = false)
    # FIXME (rspeicher): This was breaking things.
    # if mentioner.is_a?(Commit) && cross_reference
    #   return mentioner.gfm_reference.sub('commit ', 'commit %')
    # end

    full_gfm_reference(mentioner.project, noteable.project, mentioner)
  end

  # Return the +mentioner+ GFM reference.  If the mentioner and noteable
  # projects are not the same, add the mentioning project's path to the
  # returned value.
  def self.full_gfm_reference(mentioning_project, noteable_project, mentioner)
    if mentioning_project == noteable_project
      mentioner.gfm_reference
    else
      if mentioner.is_a?(Commit)
        mentioner.gfm_reference.sub(
          /(commit )/,
          "\\1#{mentioning_project.path_with_namespace}@"
        )
      else
        mentioner.gfm_reference.sub(
          /(issue |merge request )/,
          "\\1#{mentioning_project.path_with_namespace}"
        )
      end
    end
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
      "* #{commit.short_id} - #{commit.title}"
    end
  end

  # Build a single line summarizing existing commits being added in a merge
  # request
  #
  # noteable         - MergeRequest object
  # existing_commits - Array of existing Commit objects
  # oldrev           - Optional String SHA of ... TODO (rspeicher): I have no idea what this actually does.
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
                   if oldrev
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
end
