class NewNoteWorker
  include ApplicationWorker

  # Keep extra parameter to preserve backwards compatibility with
  # old `NewNoteWorker` jobs (can remove later)
  def perform(note_id, _params = {})
    if note = Note.find_by(id: note_id)
      NotificationService.new.new_note(note) if note.can_create_notification?
      Notes::PostProcessService.new(note).execute
    else
      Rails.logger.error("NewNoteWorker: couldn't find note with ID=#{note_id}, skipping job")
    end
  end
end
