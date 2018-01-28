module SystemNoteHelper
  ICON_NAMES_BY_ACTION = {
    'commit' => 'commit',
    'description' => 'pencil',
    'merge' => 'git-merge',
    'merged' => 'git-merge',
    'opened' => 'issue-open',
    'closed' => 'issue-close',
    'time_tracking' => 'timer',
    'assignee' => 'user',
    'title' => 'pencil',
    'task' => 'task-done',
    'label' => 'label',
    'cross_reference' => 'comment-dots',
    'branch' => 'fork',
    'confidential' => 'eye-slash',
    'visible' => 'eye',
    'milestone' => 'clock',
    'discussion' => 'comment',
    'moved' => 'arrow-right',
    'outdated' => 'pencil',
    'duplicate' => 'issue-duplicate',
    'locked' => 'lock',
    'unlocked' => 'lock-open'
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
