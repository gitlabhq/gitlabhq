# frozen_string_literal: true

class CreateNoteDiffFileWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  feature_category :code_review

  def perform(diff_note_id)
    diff_note = DiffNote.find(diff_note_id)

    diff_note.create_diff_file
  end
end
