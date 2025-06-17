# frozen_string_literal: true

class CreateNoteDiffFileWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :code_review_workflow

  def perform(diff_note_id)
    return unless diff_note_id.present?

    diff_note = DiffNote.find_by_id(diff_note_id)

    diff_note&.create_diff_file
  rescue DiffNote::NoteDiffFileCreationError => e
    # We rescue DiffNote::NoteDiffFileCreationError since we don't want to
    # fail the job and retry as it won't make any difference if we can't find
    # the diff or diff line.
    Gitlab::ErrorTracking.track_exception(e, diff_note_id: diff_note_id)
  end
end
