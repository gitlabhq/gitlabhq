# frozen_string_literal: true

class NewNoteWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3

  feature_category :issue_tracking
  urgency :high
  worker_resource_boundary :cpu
  weight 2

  # Keep extra parameter to preserve backwards compatibility with
  # old `NewNoteWorker` jobs (can remove later)
  # rubocop: disable CodeReuse/ActiveRecord
  def perform(note_id, _params = {})
    if note = Note.find_by(id: note_id)
      NotificationService.new.new_note(note) unless note.skip_notification?
      Notes::PostProcessService.new(note).execute
    else
      Gitlab::AppLogger.error("NewNoteWorker: couldn't find note with ID=#{note_id}, skipping job")
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
