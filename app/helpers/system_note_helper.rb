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
        'icon_status_open'
      when 'closed'
        'icon_status_closed'
      when 'time_tracking'
        'icon_stopwatch'
      when 'assignee'
        'icon_user'
      when 'title'
        'icon_pencil'
      when 'task'
        'icon_check_square_o'
      when 'label'
        'icon_tags'
      when 'cross_reference'
        'icon_random'
      when 'branch'
        'icon_code_fork'
      when 'confidential'
        'icon_eye_slash'
      when 'visible'
        'icon_eye'
      when 'milestone'
        'icon_clock_o'
      when 'discussion'
        'icon_comment_o'
      when 'moved'
        'icon_arrow-circle-o-right'
      else
        'icon_diamond'
      end

    custom_icon(icon_name)
  end
end
