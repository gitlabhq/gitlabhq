class CreateIndexCiPipelinesAutoCanceledById < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # MySQL would already have the index
    unless index_exists?(:ci_pipelines, :auto_canceled_by_id)
      add_concurrent_index(:ci_pipelines, :auto_canceled_by_id)
    end
  end

  def down
    # We cannot remove index for MySQL because it's needed for foreign key
    if Gitlab::Database.postgresql?
      remove_concurrent_index(:ci_pipelines, :auto_canceled_by_id)
    end
  end
end
