class NewNoteWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform(note_id)
    if note = Note.find_by(id: note_id)
      NotificationService.new.new_note(note)
      Notes::PostProcessService.new(note).execute
    else
      Rails.logger.error("NewNoteWorker: couldn't find note with ID=#{note_id}, skipping job")
    end
  end
end
