# frozen_string_literal: true

module SystemNotes
  class IssuablesService < ::SystemNotes::BaseService
    # We create cross-referenced system notes when a commit relates to an issue.
    # There are two options what time to use for the system note:
    # 1. The push date (default)
    # 2. The commit date
    #
    # The commit date is useful when an existing Git repository is imported to GitLab.
    # It helps to preserve an original order of all notes (comments, commits, status changes, e.t.c)
    # in the imported issues. Otherwise, all commits will be linked before or after all other imported notes.
    #
    # See also the discussion in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/60700#note_612724683
    USE_COMMIT_DATE_FOR_CROSS_REFERENCE_NOTE = false

    #
    # noteable_ref - Referenced noteable object
    #
    # Example Note text:
    #
    #   "marked this issue as related to gitlab-foss#9001"
    #
    # Returns the created Note object
    def relate_issuable(noteable_ref)
      issuable_type = noteable.to_ability_name.humanize(capitalize: false)
      body = "marked this #{issuable_type} as related to #{noteable_ref.to_reference(noteable.resource_parent)}"

      issue_activity_counter.track_issue_related_action(author: author) if noteable.is_a?(Issue)

      create_note(NoteSummary.new(noteable, project, author, body, action: 'relate'))
    end

    #
    # noteable_ref - Referenced noteable object
    #
    # Example Note text:
    #
    #   "removed the relation with gitlab-foss#9001"
    #
    # Returns the created Note object
    def unrelate_issuable(noteable_ref)
      body = "removed the relation with #{noteable_ref.to_reference(noteable.resource_parent)}"

      issue_activity_counter.track_issue_unrelated_action(author: author) if noteable.is_a?(Issue)

      create_note(NoteSummary.new(noteable, project, author, body, action: 'unrelate'))
    end

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

      issue_activity_counter.track_issue_assignee_changed_action(author: author) if noteable.is_a?(Issue)

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

      issue_activity_counter.track_issue_assignee_changed_action(author: author) if noteable.is_a?(Issue)

      create_note(NoteSummary.new(noteable, project, author, body, action: 'assignee'))
    end

    # Called when the reviewers of an issuable is changed or removed
    #
    # reviewers - Users being requested to review, or nil
    #
    # Example Note text:
    #
    #   "requested review from @user1 and @user2"
    #
    #   "requested review from @user1, @user2 and @user3 and removed review request for @user4 and @user5"
    #
    # Returns the created Note object
    def change_issuable_reviewers(old_reviewers)
      unassigned_users = old_reviewers - noteable.reviewers
      added_users = noteable.reviewers - old_reviewers
      text_parts = []

      Gitlab::I18n.with_default_locale do
        text_parts << "requested review from #{added_users.map(&:to_reference).to_sentence}" if added_users.any?
        text_parts << "removed review request for #{unassigned_users.map(&:to_reference).to_sentence}" if unassigned_users.any?
      end

      body = text_parts.join(' and ')

      create_note(NoteSummary.new(noteable, project, author, body, action: 'reviewer'))
    end

    # Called when the contacts of an issuable are changed or removed
    # We intend to reference the contacts but for security we are just
    # going to state how many were added/removed for now. See discussion:
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/77816#note_806114273
    #
    # added_count - number of contacts added, or 0
    # removed_count - number of contacts  removed, or 0
    #
    # Example Note text:
    #
    #   "added 2 contacts"
    #
    #   "added 3 contacts and removed one contact"
    #
    # Returns the created Note object
    def change_issuable_contacts(added_count, removed_count)
      text_parts = []

      Gitlab::I18n.with_default_locale do
        text_parts << "added #{added_count} #{'contact'.pluralize(added_count)}" if added_count > 0
        text_parts << "removed #{removed_count} #{'contact'.pluralize(removed_count)}" if removed_count > 0
      end

      return if text_parts.empty?

      body = text_parts.join(' and ')
      create_note(NoteSummary.new(noteable, project, author, body, action: 'contact'))
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

      marked_old_title = Gitlab::Diff::InlineDiffMarkdownMarker.new(old_title).mark(old_diffs)
      marked_new_title = Gitlab::Diff::InlineDiffMarkdownMarker.new(new_title).mark(new_diffs)

      body = "changed title from **#{marked_old_title}** to **#{marked_new_title}**"

      issue_activity_counter.track_issue_title_changed_action(author: author) if noteable.is_a?(Issue)
      work_item_activity_counter.track_work_item_title_changed_action(author: author) if noteable.is_a?(WorkItem)

      create_note(NoteSummary.new(noteable, project, author, body, action: 'title'))
    end

    # Called when the hierarchy of a work item is changed
    #
    # noteable  - Noteable object that responds to `work_item_parent` and `work_item_children`
    # project   - Project owning noteable
    # author    - User performing the change
    #
    # Example Note text:
    #
    #   "added #1 as child Task"
    #
    # Returns the created Note object
    def hierarchy_changed(work_item, action)
      params = hierarchy_note_params(action, noteable, work_item)

      create_note(NoteSummary.new(noteable, project, author, params[:parent_note_body], action: params[:parent_action]))
      create_note(NoteSummary.new(work_item, project, author, params[:child_note_body], action: params[:child_action]))
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

      issue_activity_counter.track_issue_description_changed_action(author: author) if noteable.is_a?(Issue)

      create_note(NoteSummary.new(noteable, project, author, body, action: 'description'))
    end

    # Called when a Mentionable (the `mentioned_in`) references another Mentionable (the `mentioned`,
    # passed to this service as `noteable`).
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
    # @param mentioned_in [Mentionable]
    # @return [Note]
    def cross_reference(mentioned_in)
      return if cross_reference_disallowed?(mentioned_in)

      gfm_reference = mentioned_in.gfm_reference(noteable.project || noteable.group)
      body = cross_reference_note_content(gfm_reference)

      if noteable.is_a?(ExternalIssue)
        Integrations::CreateExternalCrossReferenceWorker.perform_async(
          noteable.project_id,
          noteable.id,
          mentioned_in.class.name,
          mentioned_in.id,
          author.id
        )
      else
        track_cross_reference_action
        created_at = mentioner.created_at if USE_COMMIT_DATE_FOR_CROSS_REFERENCE_NOTE && mentioner.is_a?(Commit)
        create_note(NoteSummary.new(noteable, noteable.project, author, body, action: 'cross_reference', created_at: created_at))
      end
    end

    # Check if a cross-reference is disallowed
    #
    # This method prevents adding a "mentioned in !1" note on every single commit
    # in a merge request. Additionally, it prevents the creation of references to
    # external issues (which would fail).
    #
    # @param mentioned_in [Mentionable]
    # @return [Boolean]
    def cross_reference_disallowed?(mentioned_in)
      return true if noteable.is_a?(ExternalIssue) && !noteable.project&.external_references_supported?
      return false unless mentioned_in.is_a?(MergeRequest)
      return false unless noteable.is_a?(Commit)

      mentioned_in.commits.include?(noteable)
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

      issue_activity_counter.track_issue_description_changed_action(author: author) if noteable.is_a?(Issue)

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

      issue_activity_counter.track_issue_moved_action(author: author) if noteable.is_a?(Issue)

      create_note(NoteSummary.new(noteable, project, author, body, action: 'moved'))
    end

    # Called when noteable has been cloned
    #
    # noteable_ref - Referenced noteable
    # direction    - symbol, :to or :from
    #
    # Example Note text:
    #
    #   "cloned to some_namespace/project_new#11"
    #
    # Returns the created Note object
    def noteable_cloned(noteable_ref, direction)
      unless [:to, :from].include?(direction)
        raise ArgumentError, "Invalid direction `#{direction}`"
      end

      cross_reference = noteable_ref.to_reference(project)
      body = "cloned #{direction} #{cross_reference}"

      issue_activity_counter.track_issue_cloned_action(author: author) if noteable.is_a?(Issue) && direction == :to

      create_note(NoteSummary.new(noteable, project, author, body, action: 'cloned'))
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

        issue_activity_counter.track_issue_made_confidential_action(author: author) if noteable.is_a?(Issue)
      else
        body = 'made the issue visible to everyone'
        action = 'visible'

        issue_activity_counter.track_issue_made_visible_action(author: author) if noteable.is_a?(Issue)
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
      create_resource_state_event(status: status, mentionable_source: source)
    end

    # Check if a cross reference to a Mentionable from the `mentioned_in` Mentionable
    # already exists.
    #
    # This method is used to prevent multiple notes being created for a mention
    # when a issue is updated, for example. The method also calls `existing_mentions_for`
    # to check if the mention is in a commit, and return matches only on commit hash
    # instead of project + commit, to avoid repeated mentions from forks.
    #
    # @param mentioned_in [Mentionable]
    # @return [Boolean]
    def cross_reference_exists?(mentioned_in)
      notes = noteable.notes.system
      existing_mentions_for(mentioned_in, noteable, notes).exists?
    end

    # Called when a user's attention has been requested for a Notable
    #
    # user - User's whos attention has been requested
    #
    # Example Note text:
    #
    #   "requested attention from @eli.wisoky"
    #
    # Returns the created Note object
    def request_attention(user)
      body = "requested attention from #{user.to_reference}"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'attention_requested'))
    end

    # Called when a user's attention request has been removed for a Notable
    #
    # user - User's whos attention request has been removed
    #
    # Example Note text:
    #
    #   "removed attention request from @eli.wisoky"
    #
    # Returns the created Note object
    def remove_attention_request(user)
      body = "removed attention request from #{user.to_reference}"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'attention_request_removed'))
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

      issue_activity_counter.track_issue_marked_as_duplicate_action(author: author) if noteable.is_a?(Issue)

      create_note(NoteSummary.new(noteable, project, author, body, action: 'duplicate'))
    end

    def add_email_participants(body)
      create_note(NoteSummary.new(noteable, project, author, body))
    end

    def discussion_lock
      action = noteable.discussion_locked? ? 'locked' : 'unlocked'
      body = "#{action} this #{noteable.class.to_s.titleize.downcase}"

      if noteable.is_a?(Issue)
        if action == 'locked'
          issue_activity_counter.track_issue_locked_action(author: author)
        else
          issue_activity_counter.track_issue_unlocked_action(author: author)
        end
      end

      create_note(NoteSummary.new(noteable, project, author, body, action: action))
    end

    def close_after_error_tracking_resolve
      create_resource_state_event(status: 'closed', close_after_error_tracking_resolve: true)
    end

    def auto_resolve_prometheus_alert
      create_resource_state_event(status: 'closed', close_auto_resolve_prometheus_alert: true)
    end

    def change_issue_type
      body = "changed issue type to #{noteable.issue_type.humanize(capitalize: false)}"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'issue_type'))
    end

    private

    def cross_reference_note_content(gfm_reference)
      "#{self.class.cross_reference_note_prefix}#{gfm_reference}"
    end

    def existing_mentions_for(mentioned_in, noteable, notes)
      if mentioned_in.is_a?(Commit)
        text = "#{self.class.cross_reference_note_prefix}%#{mentioned_in.to_reference(nil)}"
        notes.like_note_or_capitalized_note(text)
      else
        gfm_reference = mentioned_in.gfm_reference(noteable.project || noteable.group)
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

    def create_resource_state_event(params)
      ResourceEvents::ChangeStateService.new(resource: noteable, user: author)
        .execute(params)
    end

    def issue_activity_counter
      Gitlab::UsageDataCounters::IssueActivityUniqueCounter
    end

    def work_item_activity_counter
      Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter
    end

    def track_cross_reference_action
      issue_activity_counter.track_issue_cross_referenced_action(author: author) if noteable.is_a?(Issue)
    end

    def hierarchy_note_params(action, parent, child)
      return {} unless child && parent

      child_type = child.issue_type.humanize(capitalize: false)
      parent_type = parent.issue_type.humanize(capitalize: false)

      if action == 'relate'
        {
          parent_note_body: "added #{child.to_reference} as child #{child_type}",
          child_note_body: "added #{parent.to_reference} as parent #{parent_type}",
          parent_action: 'relate_to_child',
          child_action: 'relate_to_parent'
        }
      else
        {
          parent_note_body: "removed child #{child_type} #{child.to_reference}",
          child_note_body: "removed parent #{parent_type} #{parent.to_reference}",
          parent_action: 'unrelate_from_child',
          child_action: 'unrelate_from_parent'
        }
      end
    end
  end
end

SystemNotes::IssuablesService.prepend_mod_with('SystemNotes::IssuablesService')
