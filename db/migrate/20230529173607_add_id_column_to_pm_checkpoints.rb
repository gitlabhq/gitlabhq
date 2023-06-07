# frozen_string_literal: true

class AddIdColumnToPmCheckpoints < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    add_column(:pm_checkpoints, :id, :bigserial)
    add_index(:pm_checkpoints, :id, unique: true, name: :pm_checkpoints_unique_index) # rubocop:disable Migration/AddIndex
    add_index(:pm_checkpoints, [:purl_type, :data_type, :version_format], unique: true, # rubocop:disable Migration/AddIndex
      name: :pm_checkpoints_path_components)
    swap_primary_key(:pm_checkpoints, :pm_checkpoints_pkey, :pm_checkpoints_unique_index)
  end

  def down
    add_index(:pm_checkpoints, [:purl_type, :data_type, :version_format], unique: true, # rubocop:disable Migration/AddIndex
      name: :pm_checkpoints_unique_index)
    remove_index(:pm_checkpoints, name: :pm_checkpoints_path_components) # rubocop:disable Migration/RemoveIndex
    unswap_primary_key(:pm_checkpoints, :pm_checkpoints_pkey, :pm_checkpoints_unique_index)
    remove_column(:pm_checkpoints, :id)
  end
end
