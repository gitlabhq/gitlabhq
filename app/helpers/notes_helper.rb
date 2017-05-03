module NotesHelper
  def note_target_fields(note)
    if note.noteable
      hidden_field_tag(:target_type, note.noteable.class.name.underscore) +
        hidden_field_tag(:target_id, note.noteable.id)
    end
  end

  def note_editable?(note)
    Ability.can_edit_note?(current_user, note)
  end

  def note_supports_slash_commands?(note)
    Notes::SlashCommandsService.supported?(note, current_user)
  end

  def noteable_json(noteable)
    {
      id: noteable.id,
      class: noteable.class.name,
      resources: noteable.class.table_name,
      project_id: noteable.project.id,
    }.to_json
  end

  def diff_view_data
    return {} unless @new_diff_note_attrs

    @new_diff_note_attrs.slice(:noteable_id, :noteable_type, :commit_id)
  end

  def diff_view_line_data(line_code, position, line_type)
    return if @diff_notes_disabled

    data = {
      line_code: line_code,
      line_type: line_type,
    }

    if @use_legacy_diff_notes
      data[:note_type] = LegacyDiffNote.name
    else
      data[:note_type] = DiffNote.name
      data[:position] = position.to_json
    end

    data
  end

  def link_to_reply_discussion(discussion, line_type = nil)
    return unless current_user

    data = { discussion_id: discussion.id, line_type: line_type }

    button_tag 'Reply...', class: 'btn btn-text-field js-discussion-reply-button',
                           data: data, title: 'Add a reply'
  end

  def note_max_access_for_user(note)
    note.project.team.human_max_access(note.author_id)
  end

  def discussion_path(discussion)
    if discussion.for_merge_request?
      return unless discussion.diff_discussion?

      version_params = discussion.merge_request_version_params
      return unless version_params

      path_params = version_params.merge(anchor: discussion.line_code)

      diffs_namespace_project_merge_request_path(discussion.project.namespace, discussion.project, discussion.noteable, path_params)
    elsif discussion.for_commit?
      anchor = discussion.line_code if discussion.diff_discussion?

      namespace_project_commit_path(discussion.project.namespace, discussion.project, discussion.noteable, anchor: anchor)
    end
  end
end
