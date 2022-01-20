# frozen_string_literal: true

class AddMaintainerNoteToCiRunners < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    # rubocop:disable Migration/AddLimitToTextColumns
    # limit is added in 20220111095007_add_text_limit_to_ci_runners_maintainer_note.rb
    add_column :ci_runners, :maintainer_note, :text
    # rubocop:enable Migration/AddLimitToTextColumns
  end
end
