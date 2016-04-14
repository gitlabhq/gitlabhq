module NotesHelper
  # Helps to distinguish e.g. commit notes in mr notes list
  def note_for_main_target?(note)
    (@noteable.class.name == note.noteable_type && !note.for_diff_line?)
  end

  def note_target_fields(note)
    if note.noteable
      hidden_field_tag(:target_type, note.noteable.class.name.underscore) +
        hidden_field_tag(:target_id, note.noteable.id)
    end
  end

  def note_editable?(note)
    note.editable? && can?(current_user, :admin_note, note)
  end

  def link_to_commit_diff_line_note(note)
    if note.for_commit_diff_line?
      link_to(
        "#{note.diff_file_name}:L#{note.diff_new_line}",
        namespace_project_commit_path(@project.namespace, @project,
                                      note.noteable, anchor: note.line_code)
      )
    end
  end

  def noteable_json(noteable)
    {
      id: noteable.id,
      class: noteable.class.name,
      resources: noteable.class.table_name,
      project_id: noteable.project.id,
    }.to_json
  end

  def link_to_new_diff_note(line_code, line_type = nil)
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
      discussion_id: discussion_id,
      line_type:     line_type
    }

    button_tag(class: 'btn add-diff-note js-add-diff-note-button',
               data: data,
               title: 'Add a comment to this line') do
      icon('comment-o')
    end
  end

  def link_to_reply_diff(note, line_type = nil)
    return unless current_user

    data = {
      noteable_type: note.noteable_type,
      noteable_id:   note.noteable_id,
      commit_id:     note.commit_id,
      line_code:     note.line_code,
      discussion_id: note.discussion_id,
      line_type:     line_type
    }

    button_tag 'Reply...', class: 'btn btn-text-field js-discussion-reply-button',
                           data: data, title: 'Add a reply'
  end

  CHANGED_REGEX = /^(title|status|milestone) changed/i.freeze
  DOWNCASE_FIRST_REGEX = /^(removed|reassigned|added|mentioned)/i.freeze
  def system_note_text(note_text)
    if note_text =~ CHANGED_REGEX
      note_text.gsub!(CHANGED_REGEX) { "changed #{Regexp.last_match[1].downcase}" }
    elsif note_text =~ DOWNCASE_FIRST_REGEX
      note_text.sub!(/^[A-Z]/, &:downcase)
    elsif note_text == "Assignee removed"
      note_text = "removed assignee"
    end

    note_text
  end

  LABEL_REGEX = /^(added|removed) (.*) label/i.freeze
  TITLE_REGEX = /^title changed/i.freeze
  MILESTONE_REGEX = /^milestone changed/i.freeze
  STATUS_CLOSED_REGEX = /^status changed to closed/i.freeze
  STATUS_OPEN_REGEX = /^status changed to (open|reopened)/i.freeze
  ASSIGNEE_REGEX = /^(reassigned|assignee)/i.freeze
  MENTIONED_REGEX = /^(mentioned)/i.freeze
  def system_note_icon(note_text)
    if note_text =~ LABEL_REGEX
      'tags'
    elsif note_text =~ TITLE_REGEX
      'pencil'
    elsif note_text =~ MILESTONE_REGEX
      'clock-o'
    elsif note_text =~ STATUS_CLOSED_REGEX
      'check'
    elsif note_text =~ STATUS_OPEN_REGEX
      'circle-o'
    elsif note_text =~ ASSIGNEE_REGEX
      'user'
    elsif note_text =~ MENTIONED_REGEX
      'bookmark'
    end
  end
end
