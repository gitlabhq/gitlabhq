class AddForeignKeyToMergeRequests < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    execute <<-SQL.strip_heredoc
      UPDATE merge_requests SET head_pipeline_id = null
        WHERE NOT EXISTS (
          SELECT 1 FROM ci_pipelines
            WHERE ci_pipelines.id = merge_requests.head_pipeline_id
        )
    SQL

    unless foreign_key_exists?(:merge_requests, :head_pipeline_id)
      add_concurrent_foreign_key(:merge_requests, :ci_pipelines,
                                 column: :head_pipeline_id, on_delete: :nullify)
    end
  end

  def down
    if foreign_key_exists?(:merge_requests, :head_pipeline_id)
      remove_foreign_key(:merge_requests, column: :head_pipeline_id)
    end
  end

  private

  def foreign_key_exists?(table, column)
    foreign_keys(table).any? do |key|
      key.options[:column] == column.to_s
    end
  end
end
