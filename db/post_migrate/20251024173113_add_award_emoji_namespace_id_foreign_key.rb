# frozen_string_literal: true

class AddAwardEmojiNamespaceIdForeignKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    add_concurrent_foreign_key :award_emoji,
      :namespaces,
      column: :namespace_id,
      target_column: :id,
      validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :award_emoji, column: :namespace_id
    end
  end
end
