module SystemNoteHelper
  def icon_for_system_note(note)

    icon_name =
      case note.system_note_metadata.action
      when 'commit'
        'icon_commit'
      when 'merge'
        'icon_merge'
      when 'merged'
        'icon_merged'
      when 'opened'
        'icon_opened'
      when 'closed'
        'icon_closed'
      when 'time_tracking'
        'icon_timer'
      when 'assignee'
        'icon_user'
      when 'title'
        'icon_pencil'
      else
        'icon_status_canceled'
      end

    custom_icon(icon_name)
  end
end
