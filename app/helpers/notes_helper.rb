module NotesHelper
   # Helps to distinguish e.g. commit notes in mr notes list
  def note_for_main_target?(note)
    (@noteable.class.name == note.noteable_type && !note.for_diff_line?)
  end

  def note_target_fields
    hidden_field_tag(:target_type, @target_type) +
    hidden_field_tag(:target_id, @target_id)
  end

  def link_to_commit_diff_line_note(note)
    if note.for_commit_diff_line?
      link_to "#{note.diff_file_name}:L#{note.diff_new_line}", project_commit_path(@project, note.noteable, anchor: note.line_code)
    end
  end

  def note_timestamp(note)
    # Shows the created at time and the updated at time if different
    ts = "#{time_ago_with_tooltip(note.created_at, 'bottom', 'note_created_ago')}"
    if note.updated_at != note.created_at
      ts << capture_haml do
        haml_tag :small do
          haml_concat " (Edited #{time_ago_with_tooltip(note.updated_at, 'bottom', 'note_edited_ago')})"
        end
      end
    end
    ts.html_safe
  end

  def noteable_json(noteable)
    {
      id: noteable.id,
      class: noteable.class.name,
      resources: noteable.class.table_name,
      project_id: noteable.project.id,
    }.to_json
  end

  def link_to_new_diff_note(line_code)
    discussion_id = Note.build_discussion_id(
      @comments_target[:noteable_type],
      @comments_target[:noteable_id] || @comments_target[:commit_id],
      line_code
    )

    data = {
      noteable_type: @comments_target[:noteable_type],
      noteable_id:   @comments_target[:noteable_id],
      commit_id:     @comments_target[:commit_id],
      line_code:     line_code,
      discussion_id: discussion_id
    }

    link_to "", "javascript:;", class: "add-diff-note js-add-diff-note-button",
      data: data, title: "Add a comment to this line"
  end

  def link_to_reply_diff(note)
    return unless current_user

    data = {
      noteable_type: note.noteable_type,
      noteable_id:   note.noteable_id,
      commit_id:     note.commit_id,
      line_code:     note.line_code,
      discussion_id: note.discussion_id
    }

    link_to "javascript:;", class: "btn reply-btn js-discussion-reply-button",
      data: data, title: "Add a reply" do
      link_text = ""
      link_text < content_tag(:i, nil, class: 'icon-comment')
      link_text << "Reply"
      end
  end
end
