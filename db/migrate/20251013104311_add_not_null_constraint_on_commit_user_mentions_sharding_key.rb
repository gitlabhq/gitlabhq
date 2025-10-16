# frozen_string_literal: true

class AddNotNullConstraintOnCommitUserMentionsShardingKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    add_not_null_constraint :commit_user_mentions, :namespace_id, validate: false
  end

  def down
    remove_not_null_constraint :commit_user_mentions, :namespace_id
  end
end
