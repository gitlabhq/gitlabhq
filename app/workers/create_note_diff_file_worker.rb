# frozen_string_literal: true

class CreateNoteDiffFileWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :code_review

  def perform(diff_note_id)
    diff_note = DiffNote.find_by_id(diff_note_id) # rubocop: disable CodeReuse/ActiveRecord

    diff_note&.create_diff_file
  end
end
