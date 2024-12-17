# frozen_string_literal: true

class AddShardingKeyIdToUploads < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def up
    add_column :uploads, :organization_id, :bigint
    add_column :uploads, :namespace_id, :bigint
    add_column :uploads, :project_id, :bigint
  end

  def down
    remove_column :uploads, :project_id
    remove_column :uploads, :namespace_id
    remove_column :uploads, :organization_id
  end
end
