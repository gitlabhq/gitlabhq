# frozen_string_literal: true

class RemoveDeprecatedIndexFromAwardEmoji < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_award_emoji_on_user_id_and_name'

  disable_ddl_transaction!

  def up
    # Index deprecated in favor of idx_award_emoji_on_user_emoji_name_awardable_type_awardable_id
    remove_concurrent_index_by_name(:award_emoji, INDEX_NAME)
  end

  def down
    add_concurrent_index(:award_emoji, [:user_id, :name], name: INDEX_NAME)
  end
end
