# frozen_string_literal: true

class AddShardingKeyToCommitUserMentions < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def change
    add_column :commit_user_mentions, :namespace_id, :bigint
  end
end
