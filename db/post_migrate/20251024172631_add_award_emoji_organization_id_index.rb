# frozen_string_literal: true

class AddAwardEmojiOrganizationIdIndex < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_award_emoji_on_organization_id'

  disable_ddl_transaction!
  milestone '18.6'

  def up
    add_concurrent_index :award_emoji, :organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :award_emoji, INDEX_NAME
  end
end
