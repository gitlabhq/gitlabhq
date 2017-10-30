class AddCustomEmojiIdOnAwardEmoji < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_reference :award_emoji, :custom_emoji, index: true, foreign_key: { on_delete: :cascade }
  end

  def down
    remove_foreign_key :award_emoji, :custom_emoji
    remove_reference :award_emoji, :custom_emoji
  end
end
