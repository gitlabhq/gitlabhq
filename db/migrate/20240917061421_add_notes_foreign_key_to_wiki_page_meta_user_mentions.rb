# frozen_string_literal: true

class AddNotesForeignKeyToWikiPageMetaUserMentions < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :wiki_page_meta_user_mentions, :notes, column: :note_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :wiki_page_meta_user_mentions, column: :note_id
    end
  end
end
