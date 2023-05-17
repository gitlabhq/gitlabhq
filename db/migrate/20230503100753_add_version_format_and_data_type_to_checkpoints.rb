# frozen_string_literal: true

class AddVersionFormatAndDataTypeToCheckpoints < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    add_column(:pm_checkpoints, :data_type, :integer, limit: 2, default: 1, null: false)
    add_column(:pm_checkpoints, :version_format, :integer, limit: 2, default: 1, null: false)
    add_index(:pm_checkpoints, [:purl_type, :data_type, :version_format], unique: true, name: :pm_checkpoints_unique_index) # rubocop:disable Migration/AddIndex
    swap_primary_key(:pm_checkpoints, :pm_checkpoints_pkey, :pm_checkpoints_unique_index)
  end

  def down
    add_index(:pm_checkpoints, [:purl_type], unique: true, name: :pm_checkpoints_unique_index) # rubocop:disable Migration/AddIndex
    unswap_primary_key(:pm_checkpoints, :pm_checkpoints_pkey, :pm_checkpoints_unique_index)
    remove_column(:pm_checkpoints, :version_format)
    remove_column(:pm_checkpoints, :data_type)
  end
end
