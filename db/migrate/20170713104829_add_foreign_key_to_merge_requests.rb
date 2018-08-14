class AddForeignKeyToMergeRequests < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class MergeRequest < ActiveRecord::Base
    self.table_name = 'merge_requests'
    include ::EachBatch
  end

  def up
    scope = <<-SQL.strip_heredoc
      head_pipeline_id IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM ci_pipelines
            WHERE ci_pipelines.id = merge_requests.head_pipeline_id
        )
    SQL

    MergeRequest.where(scope).each_batch(of: 1000) do |merge_requests|
      merge_requests.update_all(head_pipeline_id: nil)
    end

    unless foreign_key_exists?(:merge_requests, column: :head_pipeline_id)
      add_concurrent_foreign_key(:merge_requests, :ci_pipelines,
                                 column: :head_pipeline_id, on_delete: :nullify)
    end
  end

  def down
    if foreign_key_exists?(:merge_requests, column: :head_pipeline_id)
      remove_foreign_key(:merge_requests, column: :head_pipeline_id)
    end
  end
end
