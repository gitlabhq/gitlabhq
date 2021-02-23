# frozen_string_literal: true

class AddCreatorForeignKeyToCustomEmoji < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  FK_NAME = 'fk_custom_emoji_creator_id'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :custom_emoji, :users,
                               on_delete: :cascade,
                               column: :creator_id,
                               name: FK_NAME
  end

  def down
    with_lock_retries do
      remove_foreign_key :custom_emoji, name: FK_NAME
    end
  end
end
