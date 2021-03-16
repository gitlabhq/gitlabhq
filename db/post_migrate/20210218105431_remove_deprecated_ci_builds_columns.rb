# frozen_string_literal: true

class RemoveDeprecatedCiBuildsColumns < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_column :ci_builds, :artifacts_file
      remove_column :ci_builds, :artifacts_file_store
      remove_column :ci_builds, :artifacts_metadata
      remove_column :ci_builds, :artifacts_metadata_store
      remove_column :ci_builds, :artifacts_size
      remove_column :ci_builds, :commands
    end
  end

  def down
    # rubocop:disable Migration/AddColumnsToWideTables
    with_lock_retries do
      add_column :ci_builds, :artifacts_file, :text
      add_column :ci_builds, :artifacts_file_store, :integer
      add_column :ci_builds, :artifacts_metadata, :text
      add_column :ci_builds, :artifacts_metadata_store, :integer
      add_column :ci_builds, :artifacts_size, :bigint
      add_column :ci_builds, :commands, :text
    end
    # rubocop:enable Migration/AddColumnsToWideTables

    add_concurrent_index :ci_builds, :artifacts_expire_at, where: "artifacts_file <> ''::text", name: 'index_ci_builds_on_artifacts_expire_at'
  end
end
