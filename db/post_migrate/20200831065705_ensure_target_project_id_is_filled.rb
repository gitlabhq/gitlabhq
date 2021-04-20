# frozen_string_literal: true

class EnsureTargetProjectIdIsFilled < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  BACKGROUND_MIGRATION_CLASS = 'CopyMergeRequestTargetProjectToMergeRequestMetrics'
  BATCH_SIZE = 1_000
  DOWNTIME = false

  disable_ddl_transaction!

  class MergeRequest < ActiveRecord::Base
    self.table_name = 'merge_requests'
  end

  class MergeRequestMetrics < ActiveRecord::Base
    include EachBatch

    belongs_to :merge_request

    self.table_name = 'merge_request_metrics'
  end

  def up
    Gitlab::BackgroundMigration.steal(BACKGROUND_MIGRATION_CLASS)

    # Do a manual update in case we lost BG jobs. The expected record count should be 0 or very low.
    MergeRequestMetrics.where(target_project_id: nil).each_batch do |scope|
      query_for_cte = scope.joins(:merge_request).select(
        MergeRequestMetrics.arel_table[:id].as('id'),
        MergeRequest.arel_table[:target_project_id].as('target_project_id')
      )

      MergeRequestMetrics.connection.execute <<-SQL
        WITH target_project_id_and_metrics_id as #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (
          #{query_for_cte.to_sql}
        )
        UPDATE #{MergeRequestMetrics.connection.quote_table_name(MergeRequestMetrics.table_name)}
        SET target_project_id = target_project_id_and_metrics_id.target_project_id
        FROM target_project_id_and_metrics_id
        WHERE merge_request_metrics.id = target_project_id_and_metrics_id.id
      SQL
    end
  end

  def down
    # no-op
  end
end
