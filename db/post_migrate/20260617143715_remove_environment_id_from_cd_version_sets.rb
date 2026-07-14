# frozen_string_literal: true

class RemoveEnvironmentIdFromCdVersionSets < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  TABLE_NAME = :cd_version_sets

  def up
    with_lock_retries do
      remove_column TABLE_NAME, :environment_id, if_exists: true
    end
  end

  def down
    with_lock_retries do
      add_column TABLE_NAME, :environment_id, :bigint unless column_exists?(TABLE_NAME, :environment_id)
    end
  end
end
