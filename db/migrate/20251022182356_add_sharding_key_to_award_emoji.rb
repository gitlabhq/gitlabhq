# frozen_string_literal: true

class AddShardingKeyToAwardEmoji < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def change
    add_column :award_emoji, :namespace_id, :bigint
    add_column :award_emoji, :organization_id, :bigint
  end
end
