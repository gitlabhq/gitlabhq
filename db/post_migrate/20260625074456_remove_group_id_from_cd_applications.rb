# frozen_string_literal: true

class RemoveGroupIdFromCdApplications < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  TABLE_NAME = :cd_applications
  INDEX_NAME = :uniq_idx_cd_applications_on_group_id_and_name

  def up
    return unless table_exists?(TABLE_NAME)

    with_lock_retries do
      remove_column TABLE_NAME, :group_id, if_exists: true
    end
  end

  def down
    with_lock_retries do
      add_column TABLE_NAME, :group_id, :bigint unless column_exists?(TABLE_NAME, :group_id)
    end

    add_concurrent_index TABLE_NAME, [:group_id, :name],
      unique: true,
      where: 'group_id IS NOT NULL',
      name: INDEX_NAME
  end
end
