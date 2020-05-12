# frozen_string_literal: true

module SystemNoteHelper
  ICON_NAMES_BY_ACTION = {
    'cherry_pick' => 'cherry-pick-commit',
    'commit' => 'commit',
    'description' => 'pencil-square',
    'merge' => 'git-merge',
    'merged' => 'git-merge',
    'opened' => 'issue-open',
    'closed' => 'issue-close',
    'time_tracking' => 'timer',
    'assignee' => 'user',
    'title' => 'pencil-square',
    'task' => 'task-done',
    'label' => 'label',
    'cross_reference' => 'comment-dots',
    'branch' => 'fork',
    'confidential' => 'eye-slash',
    'visible' => 'eye',
    'milestone' => 'clock',
    'discussion' => 'comment',
    'moved' => 'arrow-right',
    'outdated' => 'pencil-square',
    'pinned_embed' => 'thumbtack',
    'duplicate' => 'duplicate',
    'locked' => 'lock',
    'unlocked' => 'lock-open',
    'due_date' => 'calendar',
    'health_status' => 'status-health',
    'designs_added' => 'doc-image',
    'designs_modified' => 'doc-image',
    'designs_removed' => 'doc-image',
    'designs_discussion_added' => 'doc-image'
  }.freeze

  def system_note_icon_name(note)
    ICON_NAMES_BY_ACTION[note.system_note_metadata&.action]
  end

  def icon_for_system_note(note)
    icon_name = system_note_icon_name(note)
    sprite_icon(icon_name) if icon_name
  end

  extend self
end

SystemNoteHelper.prepend_if_ee('EE::SystemNoteHelper')

# The methods in `EE::SystemNoteHelper` should be available as both instance and
# class methods.
SystemNoteHelper.extend_if_ee('EE::SystemNoteHelper')
