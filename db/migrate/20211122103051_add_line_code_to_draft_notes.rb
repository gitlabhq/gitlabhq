# frozen_string_literal: true

class AddLineCodeToDraftNotes < Gitlab::Database::Migration[1.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in db/migrate/20211124095704_add_draft_notes_line_code_text_limit.rb
  def change
    add_column :draft_notes, :line_code, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
