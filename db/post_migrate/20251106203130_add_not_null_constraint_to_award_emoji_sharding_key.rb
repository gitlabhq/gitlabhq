# frozen_string_literal: true

class AddNotNullConstraintToAwardEmojiShardingKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    add_multi_column_not_null_constraint(:award_emoji, :namespace_id, :organization_id, validate: false)
  end

  def down
    remove_multi_column_not_null_constraint(:award_emoji, :namespace_id, :organization_id)
  end
end
