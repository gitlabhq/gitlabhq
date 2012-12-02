class NotesController < ProjectResourceController
  # Authorize
  before_filter :authorize_read_note!
  before_filter :authorize_write_note!, only: [:create]

  respond_to :js

  def index
    @target_note = Note.new(noteable_type: params[:target_type].camelize,
                            noteable_id: params[:target_id])
    @target = @target_note.noteable
    @notes = Notes::LoadContext.new(project, current_user, params).execute

    if params[:target_type] == "merge_request"
      @has_diff      = true
      @mixed_targets = true
      @discussions   = discussions_from_notes
    elsif params[:target_type] == "commit"
      @has_diff = true
    end

    respond_with(@notes)
  end

  def create
    @note = Notes::CreateContext.new(project, current_user, params).execute

    respond_to do |format|
      format.html {redirect_to :back}
      format.js
    end
  end

  def destroy
    @note = @project.notes.find(params[:id])
    return access_denied! unless can?(current_user, :admin_note, @note)
    @note.destroy

    respond_to do |format|
      format.js { render nothing: true }
    end
  end

  def preview
    render text: view_context.markdown(params[:note])
  end

  protected

  def discussion_notes_for(note)
    @notes.select do |other_note|
      note.discussion_id == other_note.discussion_id
    end
  end

  def discussions_from_notes
    discussion_ids = []
    discussions = []

    @notes.each do |note|
      next if discussion_ids.include?(note.discussion_id)

      # don't group notes for the main target
      if for_main_target?(note)
        discussions << [note]
      else
        discussions << discussion_notes_for(note)
        discussion_ids << note.discussion_id
      end
    end

    discussions
  end

  # Helps to distinguish e.g. commit notes in mr notes list
  def for_main_target?(note)
    !@mixed_targets || (@target.class.name == note.noteable_type && !note.for_diff_line?)
  end
end
