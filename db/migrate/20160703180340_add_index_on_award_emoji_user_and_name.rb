# rubocop:disable all
# Migration type: online without errors

class AddIndexOnAwardEmojiUserAndName < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  def change
    add_concurrent_index(:award_emoji, [:user_id, :name])
  end
end
