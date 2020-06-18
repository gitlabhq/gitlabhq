# frozen_string_literal: true

module SystemNotes
  class IssuablesService < ::SystemNotes::BaseService
    # Called when the assignee of a Noteable is changed or removed
    #
    # assignee - User being assigned, or nil
    #
    # Example Note text:
    #
    #   "removed assignee"
    #
    #   "assigned to @rspeicher"
    #
    # Returns the created Note object
    def change_assignee(assignee)
      body = assignee.nil? ? 'removed assignee' : "assigned to #{assignee.to_reference}"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'assignee'))
    end

    # Called when the assignees of an issuable is changed or removed
    #
    # assignees - Users being assigned, or nil
    #
    # Example Note text:
    #
    #   "removed all assignees"
    #
    #   "assigned to @user1 additionally to @user2"
    #
    #   "assigned to @user1, @user2 and @user3 and unassigned from @user4 and @user5"
    #
    #   "assigned to @user1 and @user2"
    #
    # Returns the created Note object
    def change_issuable_assignees(old_assignees)
      unassigned_users = old_assignees - noteable.assignees
      added_users = noteable.assignees.to_a - old_assignees
      text_parts = []

      Gitlab::I18n.with_default_locale do
        text_parts << "assigned to #{added_users.map(&:to_reference).to_sentence}" if added_users.any?
        text_parts << "unassigned #{unassigned_users.map(&:to_reference).to_sentence}" if unassigned_users.any?
      end

      body = text_parts.join(' and ')

      create_note(NoteSummary.new(noteable, project, author, body, action: 'assignee'))
    end

    # Called when the milestone of a Noteable is changed
    #
    # milestone - Milestone being assigned, or nil
    #
    # Example Note text:
    #
    #   "removed milestone"
    #
    #   "changed milestone to 7.11"
    #
    # Returns the created Note object
    def change_milestone(milestone)
      format = milestone&.group_milestone? ? :name : :iid
      body = milestone.nil? ? 'removed milestone' : "changed milestone to #{milestone.to_reference(project, format: format)}"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'milestone'))
    end

    # Called when the title of a Noteable is changed
    #
    # old_title - Previous String title
    #
    # Example Note text:
    #
    #   "changed title from **Old** to **New**"
    #
    # Returns the created Note object
    def change_title(old_title)
      new_title = noteable.title.dup

      old_diffs, new_diffs = Gitlab::Diff::InlineDiff.new(old_title, new_title).inline_diffs

      marked_old_title = Gitlab::Diff::InlineDiffMarkdownMarker.new(old_title).mark(old_diffs, mode: :deletion)
      marked_new_title = Gitlab::Diff::InlineDiffMarkdownMarker.new(new_title).mark(new_diffs, mode: :addition)

      body = "changed title from **#{marked_old_title}** to **#{marked_new_title}**"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'title'))
    end

    # Called when the description of a Noteable is changed
    #
    # noteable  - Noteable object that responds to `description`
    # project   - Project owning noteable
    # author    - User performing the change
    #
    # Example Note text:
    #
    #   "changed the description"
    #
    # Returns the created Note object
    def change_description
      body = 'changed the description'

      create_note(NoteSummary.new(noteable, project, author, body, action: 'description'))
    end

    # Called when a Mentionable references a Noteable
    #
    # mentioner - Mentionable object
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
    def cross_reference(mentioner)
      return if cross_reference_disallowed?(mentioner)

      gfm_reference = mentioner.gfm_reference(noteable.project || noteable.group)
      body = cross_reference_note_content(gfm_reference)

      if noteable.is_a?(ExternalIssue)
        noteable.project.external_issue_tracker.create_cross_reference_note(noteable, mentioner, author)
      else
        create_note(NoteSummary.new(noteable, noteable.project, author, body, action: 'cross_reference'))
      end
    end

    # Check if a cross-reference is disallowed
    #
    # This method prevents adding a "mentioned in !1" note on every single commit
    # in a merge request. Additionally, it prevents the creation of references to
    # external issues (which would fail).
    #
    # mentioner - Mentionable object
    #
    # Returns Boolean
    def cross_reference_disallowed?(mentioner)
      return true if noteable.is_a?(ExternalIssue) && !noteable.project&.external_references_supported?
      return false unless mentioner.is_a?(MergeRequest)
      return false unless noteable.is_a?(Commit)

      mentioner.commits.include?(noteable)
    end

    # Called when the status of a Task has changed
    #
    # new_task  - TaskList::Item object.
    #
    # Example Note text:
    #
    #   "marked the task Whatever as completed."
    #
    # Returns the created Note object
    def change_task_status(new_task)
      status_label = new_task.complete? ? Taskable::COMPLETED : Taskable::INCOMPLETE
      body = "marked the task **#{new_task.source}** as #{status_label}"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'task'))
    end

    # Called when noteable has been moved to another project
    #
    # noteable_ref - Referenced noteable
    # direction    - symbol, :to or :from
    #
    # Example Note text:
    #
    #   "moved to some_namespace/project_new#11"
    #
    # Returns the created Note object
    def noteable_moved(noteable_ref, direction)
      unless [:to, :from].include?(direction)
        raise ArgumentError, "Invalid direction `#{direction}`"
      end

      cross_reference = noteable_ref.to_reference(project)
      body = "moved #{direction} #{cross_reference}"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'moved'))
    end

    # Called when the confidentiality changes
    #
    # Example Note text:
    #
    #   "made the issue confidential"
    #
    # Returns the created Note object
    def change_issue_confidentiality
      if noteable.confidential
        body = 'made the issue confidential'
        action = 'confidential'
      else
        body = 'made the issue visible to everyone'
        action = 'visible'
      end

      create_note(NoteSummary.new(noteable, project, author, body, action: action))
    end

    # Called when the status of a Noteable is changed
    #
    # status   - String status
    # source   - Mentionable performing the change, or nil
    #
    # Example Note text:
    #
    #   "merged"
    #
    #   "closed via bc17db76"
    #
    # Returns the created Note object
    def change_status(status, source = nil)
      body = status.dup
      body << " via #{source.gfm_reference(project)}" if source

      action = status == 'reopened' ? 'opened' : status

      # A state event which results in a synthetic note will be
      # created by EventCreateService if change event tracking
      # is enabled.
      unless state_change_tracking_enabled?
        create_note(NoteSummary.new(noteable, project, author, body, action: action))
      end
    end

    # Check if a cross reference to a noteable from a mentioner already exists
    #
    # This method is used to prevent multiple notes being created for a mention
    # when a issue is updated, for example. The method also calls notes_for_mentioner
    # to check if the mentioner is a commit, and return matches only on commit hash
    # instead of project + commit, to avoid repeated mentions from forks.
    #
    # mentioner - Mentionable object
    #
    # Returns Boolean
    def cross_reference_exists?(mentioner)
      notes = noteable.notes.system
      notes_for_mentioner(mentioner, noteable, notes).exists?
    end

    # Called when a Noteable has been marked as a duplicate of another Issue
    #
    # canonical_issue - Issue that this is a duplicate of
    #
    # Example Note text:
    #
    #   "marked this issue as a duplicate of #1234"
    #
    #   "marked this issue as a duplicate of other_project#5678"
    #
    # Returns the created Note object
    def mark_duplicate_issue(canonical_issue)
      body = "marked this issue as a duplicate of #{canonical_issue.to_reference(project)}"
      create_note(NoteSummary.new(noteable, project, author, body, action: 'duplicate'))
    end

    # Called when a Noteable has been marked as the canonical Issue of a duplicate
    #
    # duplicate_issue - Issue that was a duplicate of this
    #
    # Example Note text:
    #
    #   "marked #1234 as a duplicate of this issue"
    #
    #   "marked other_project#5678 as a duplicate of this issue"
    #
    # Returns the created Note object
    def mark_canonical_issue_of_duplicate(duplicate_issue)
      body = "marked #{duplicate_issue.to_reference(project)} as a duplicate of this issue"
      create_note(NoteSummary.new(noteable, project, author, body, action: 'duplicate'))
    end

    def discussion_lock
      action = noteable.discussion_locked? ? 'locked' : 'unlocked'
      body = "#{action} this #{noteable.class.to_s.titleize.downcase}"

      create_note(NoteSummary.new(noteable, project, author, body, action: action))
    end

    def close_after_error_tracking_resolve
      body = _('resolved the corresponding error and closed the issue.')

      create_note(NoteSummary.new(noteable, project, author, body, action: 'closed'))
    end

    def auto_resolve_prometheus_alert
      body = 'automatically closed this issue because the alert resolved.'

      create_note(NoteSummary.new(noteable, project, author, body, action: 'closed'))
    end

    private

    def cross_reference_note_content(gfm_reference)
      "#{self.class.cross_reference_note_prefix}#{gfm_reference}"
    end

    def notes_for_mentioner(mentioner, noteable, notes)
      if mentioner.is_a?(Commit)
        text = "#{self.class.cross_reference_note_prefix}%#{mentioner.to_reference(nil)}"
        notes.like_note_or_capitalized_note(text)
      else
        gfm_reference = mentioner.gfm_reference(noteable.project || noteable.group)
        text = cross_reference_note_content(gfm_reference)
        notes.for_note_or_capitalized_note(text)
      end
    end

    def self.cross_reference_note_prefix
      'mentioned in '
    end

    def self.cross_reference?(note_text)
      note_text =~ /\A#{cross_reference_note_prefix}/i
    end

    def state_change_tracking_enabled?
      noteable.respond_to?(:resource_state_events) &&
        ::Feature.enabled?(:track_resource_state_change_events, noteable.project)
    end
  end
end

SystemNotes::IssuablesService.prepend_if_ee('::EE::SystemNotes::IssuablesService')
