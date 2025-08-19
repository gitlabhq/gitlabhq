# frozen_string_literal: true

class AddShardingKeyColumnsToClusters < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    add_column :clusters, :project_id, :bigint
    add_column :clusters, :group_id, :bigint
    add_column :clusters, :organization_id, :bigint
  end
end
