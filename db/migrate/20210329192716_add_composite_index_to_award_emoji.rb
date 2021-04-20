# frozen_string_literal: true

class AddCompositeIndexToAwardEmoji < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'idx_award_emoji_on_user_emoji_name_awardable_type_awardable_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :award_emoji, %i[user_id name awardable_type awardable_id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :award_emoji, INDEX_NAME
  end
end
