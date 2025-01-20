# frozen_string_literal: true

module SystemNoteHelper
  ICON_NAMES_BY_ACTION = {
    'approved' => 'check',
    'unapproved' => 'unapproval',
    'cherry_pick' => 'cherry-pick-commit',
    'commit' => 'commit',
    'description' => 'pencil',
    'merged' => 'merge',
    'merge' => 'merge',
    'opened' => 'issues',
    'closed' => 'issue-close',
    'time_tracking' => 'timer',
    'assignee' => 'user',
    'reviewer' => 'user',
    'title' => 'pencil',
    'task' => 'todo-done',
    'label' => 'label',
    'cross_reference' => 'comment-dots',
    'branch' => 'fork',
    'confidential' => 'eye-slash',
    'visible' => 'eye',
    'milestone' => 'milestone',
    'discussion' => 'comment',
    'moved' => 'arrow-right',
    'outdated' => 'pencil',
    'pinned_embed' => 'thumbtack',
    'duplicate' => 'duplicate',
    'locked' => 'lock',
    'unlocked' => 'lock-open',
    'due_date' => 'calendar',
    'start_date_or_due_date' => 'calendar',
    'health_status' => 'status-health',
    'designs_added' => 'doc-image',
    'designs_modified' => 'doc-image',
    'designs_removed' => 'doc-image',
    'designs_discussion_added' => 'doc-image',
    'status' => 'status',
    'alert_issue_added' => 'issues',
    'new_alert_added' => 'warning',
    'severity' => 'information-o',
    'cloned' => 'documents',
    'issue_type' => 'pencil',
    'contact' => 'users',
    'timeline_event' => 'clock',
    'relate_to_child' => 'link',
    'unrelate_from_child' => 'link',
    'relate_to_parent' => 'link',
    'unrelate_from_parent' => 'link',
    'requested_changes' => 'error',
    'override' => 'review-warning'
  }.freeze

  def system_note_icon_name(note)
    if note.system_note_metadata&.action == 'closed' && note.for_merge_request?
      'merge-request-close'
    elsif note.system_note_metadata&.action == 'merge' && note.for_merge_request?
      'mr-system-note-empty'
    else
      ICON_NAMES_BY_ACTION[note.system_note_metadata&.action]
    end
  end

  def icon_for_system_note(note)
    icon_name = system_note_icon_name(note)
    sprite_icon(icon_name) if icon_name
  end

  extend self
end

SystemNoteHelper.prepend_mod_with('SystemNoteHelper')

# The methods in `EE::SystemNoteHelper` should be available as both instance and
# class methods.
SystemNoteHelper.extend_mod_with('SystemNoteHelper')
