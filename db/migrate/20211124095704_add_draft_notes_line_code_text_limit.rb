# frozen_string_literal: true

class AddDraftNotesLineCodeTextLimit < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :draft_notes, :line_code, 255
  end

  def down
    remove_text_limit :draft_notes, :line_code
  end
end
