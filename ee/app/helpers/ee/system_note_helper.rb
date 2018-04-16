module EE
  module SystemNoteHelper
    extend ::Gitlab::Utils::Override

    EE_ICON_NAMES_BY_ACTION = {
      'epic_issue_added' => 'issues',
      'epic_issue_removed' => 'issues',
      'epic_issue_moved' => 'issues',
      'issue_added_to_epic' => 'epic',
      'issue_removed_from_epic' => 'epic',
      'issue_changed_epic' => 'epic'
    }.freeze

    override :system_note_icon_name
    def system_note_icon_name(note)
      EE_ICON_NAMES_BY_ACTION[note.system_note_metadata&.action] || super
    end
  end
end
