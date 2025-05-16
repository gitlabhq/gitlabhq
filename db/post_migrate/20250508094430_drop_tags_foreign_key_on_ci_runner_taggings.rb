# frozen_string_literal: true

class DropTagsForeignKeyOnCiRunnerTaggings < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  disable_ddl_transaction!
  milestone '18.1'

  TAGGINGS_TABLE = :ci_runner_taggings
  FK_NAME = :fk_rails_6d510634c7

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(TAGGINGS_TABLE, name: FK_NAME)
    end
  end

  def down
    add_concurrent_partitioned_foreign_key TAGGINGS_TABLE, :tags, name: FK_NAME, column: :tag_id,
      on_delete: :cascade
  end
end
