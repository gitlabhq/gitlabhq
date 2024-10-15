# frozen_string_literal: true

class NewNoteWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :team_planning
  urgency :high
  worker_resource_boundary :cpu
  weight 2

  # Keep extra parameter to preserve backwards compatibility with
  # old `NewNoteWorker` jobs (can remove later)
  def perform(note_id, _params = {})
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/497631', new_threshold: 200)

    if note = Note.find_by_id(note_id)
      NotificationService.new.new_note(note) unless note.skip_notification?
      Notes::PostProcessService.new(note).execute
    else
      Gitlab::AppLogger.error("NewNoteWorker: couldn't find note with ID=#{note_id}, skipping job")
    end
  end
end
