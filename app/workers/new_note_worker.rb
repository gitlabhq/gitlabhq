class NewNoteWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform(note_id, note_params)
    note = Note.find(note_id)

    NotificationService.new.new_note(note)
    Notes::PostProcessService.new(note).execute
  end
end
