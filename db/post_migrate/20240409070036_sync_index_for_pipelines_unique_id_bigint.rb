# frozen_string_literal: true

class SyncIndexForPipelinesUniqueIdBigint < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  disable_ddl_transaction!

  TABLE = :ci_pipelines
  INDEX = {
    name: :index_ci_pipelines_on_id_convert_to_bigint,
    columns: [:id_convert_to_bigint],
    options: { unique: true }
  }

  def up
    add_concurrent_index TABLE, INDEX[:columns], name: INDEX[:name], **INDEX[:options]
  end

  def down
    remove_concurrent_index_by_name TABLE, INDEX[:name]
  end
end
