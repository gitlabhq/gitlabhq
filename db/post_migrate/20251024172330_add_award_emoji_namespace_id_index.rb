# frozen_string_literal: true

class AddAwardEmojiNamespaceIdIndex < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_award_emoji_on_namespace_id'

  disable_ddl_transaction!
  milestone '18.6'

  def up
    add_concurrent_index :award_emoji, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :award_emoji, INDEX_NAME
  end
end
