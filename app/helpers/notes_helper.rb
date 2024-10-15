# frozen_string_literal: true

module NotesHelper
  MAX_PRERENDERED_NOTES = 10

  def note_target_title(note)
    # The design title is already present in `Event#note_target_reference`.
    return if note.nil? || note.for_design?

    note.title
  end

  def note_target_fields(note)
    if note.noteable
      hidden_field_tag(:target_type, note.noteable.class.name.underscore) +
        hidden_field_tag(:target_id, note.noteable.id)
    end
  end

  def note_supports_quick_actions?(note)
    Notes::QuickActionsService.supported?(note)
  end

  def diff_view_data
    return {} unless @new_diff_note_attrs

    @new_diff_note_attrs.slice(:noteable_id, :noteable_type, :commit_id)
  end

  def diff_view_line_data(line_code, position, line_type)
    return if @diff_notes_disabled

    data = {
      line_code: line_code,
      line_type: line_type
    }

    if @use_legacy_diff_notes
      data[:note_type] = LegacyDiffNote.name
    else
      data[:note_type] = DiffNote.name
      data[:position] = Gitlab::Json.dump(position)
    end

    data
  end

  def add_diff_note_button(line_code, position, line_type)
    return if @diff_notes_disabled

    content_tag(:span, class: 'add-diff-note tooltip-wrapper') do
      button_tag '',
        class: 'note-button add-diff-note js-add-diff-note-button',
        type: 'submit', name: 'button',
        data: diff_view_line_data(line_code, position, line_type),
        title: _('Add a comment to this line') do
          sprite_icon('comment', size: 12)
        end
    end
  end

  def link_to_reply_discussion(discussion, line_type = nil)
    return unless current_user

    content_tag(
      :textarea,
      rows: 1,
      placeholder: _('Reply…'),
      'aria-label': _('Reply to comment'),
      class: 'reply-placeholder-text-field js-discussion-reply-button',
      data: {
        discussion_id: discussion.reply_id,
        discussion_project_id: discussion.project&.id,
        line_type: line_type
      }
    ) do
      # render empty textarea
    end
  end

  def note_human_max_access(note)
    note.project.team.human_max_access(note.author_id)
  end

  def discussion_path(discussion)
    if discussion.for_merge_request?
      return unless discussion.diff_discussion?

      version_params = discussion.merge_request_version_params
      return unless version_params

      path_params = version_params.merge(anchor: discussion.line_code)

      diffs_project_merge_request_path(discussion.project, discussion.noteable, path_params)
    elsif discussion.for_commit?
      anchor = discussion.diff_discussion? ? discussion.line_code : "note_#{discussion.first_note.id}"

      project_commit_path(discussion.project, discussion.noteable, anchor: anchor)
    end
  end

  def notes_url(params = {})
    if @snippet.is_a?(PersonalSnippet)
      gitlab_snippet_notes_path(@snippet, params)
    else
      params.merge!(target_id: @noteable.id, target_type: @noteable.class.name.underscore)

      project_noteable_notes_path(@project, params)
    end
  end

  def note_url(note, project = @project)
    if note.noteable.is_a?(PersonalSnippet)
      gitlab_snippet_note_path(note.noteable, note)
    else
      project_note_path(project, note)
    end
  end

  def noteable_note_url(note)
    Gitlab::UrlBuilder.build(note) if note.id
  end

  def form_resources
    if @snippet.is_a?(PersonalSnippet)
      [@note]
    else
      [@project, @note]
    end
  end

  def new_form_url
    return unless @snippet.is_a?(PersonalSnippet)

    gitlab_snippet_notes_path(@snippet)
  end

  def can_create_note?
    noteable = @issue || @merge_request || @snippet || @project

    can?(current_user, :create_note, noteable)
  end

  def initial_notes_data(autocomplete)
    {
      notesUrl: notes_url,
      now: Time.now.to_i,
      diffView: diff_view,
      enableGFM: {
        emojis: true,
        members: autocomplete,
        issues: autocomplete,
        mergeRequests: autocomplete,
        vulnerabilities: autocomplete,
        epics: autocomplete,
        milestones: autocomplete,
        labels: autocomplete
      }
    }
  end

  def discussions_path(issuable, **params)
    if issuable.is_a?(Issue)
      discussions_project_issue_path(@project, issuable, params.merge(format: :json))
    else
      discussions_project_merge_request_path(@project, issuable, params.merge(format: :json))
    end
  end

  def notes_data(issuable)
    data = {
      noteableType: @noteable.class.underscore,
      noteableId: @noteable.id,
      projectId: @project&.id,
      groupId: @group&.id,
      discussionsPath: discussions_path(issuable),
      registerPath: new_user_registration_path(redirect_to_referer: 'yes'),
      newSessionPath: new_session_path(:user, redirect_to_referer: 'yes'),
      markdownDocsPath: help_page_path('user/markdown.md'),
      quickActionsDocsPath: help_page_path('user/project/quick_actions.md'),
      closePath: close_issuable_path(issuable),
      reopenPath: reopen_issuable_path(issuable),
      notesPath: notes_url,
      prerenderedNotesCount: issuable.capped_notes_count(MAX_PRERENDERED_NOTES),
      lastFetchedAt: Time.current.to_i * NotesActions::MICROSECOND,
      notesFilter: current_user&.notes_filter_for(issuable)
    }

    if issuable.is_a?(MergeRequest)
      data.merge!(
        draftsPath: project_merge_request_drafts_path(@project, issuable),
        draftsPublishPath: publish_project_merge_request_drafts_path(@project, issuable),
        draftsDiscardPath: discard_project_merge_request_drafts_path(@project, issuable)
      )
    end

    data
  end

  def rendered_for_merge_request?
    params[:from_merge_request].present?
  end
end

NotesHelper.prepend_mod_with('NotesHelper')
