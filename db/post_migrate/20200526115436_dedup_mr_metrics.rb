# frozen_string_literal: true

class DedupMrMetrics < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  TMP_INDEX_NAME = 'tmp_unique_merge_request_metrics_by_merge_request_id'
  INDEX_NAME = 'unique_merge_request_metrics_by_merge_request_id'

  disable_ddl_transaction!

  class MergeRequestMetrics < ActiveRecord::Base
    self.table_name = 'merge_request_metrics'

    include EachBatch
  end

  def up
    last_metrics_record_id = MergeRequestMetrics.maximum(:id) || 0

    # This index will disallow further duplicates while we're deduplicating the data.
    add_concurrent_index(:merge_request_metrics, :merge_request_id, where: "id > #{Integer(last_metrics_record_id)}", unique: true, name: TMP_INDEX_NAME)

    MergeRequestMetrics.each_batch do |relation|
      duplicated_merge_request_ids = MergeRequestMetrics
        .where(merge_request_id: relation.select(:merge_request_id))
        .select(:merge_request_id)
        .group(:merge_request_id)
        .having('COUNT(merge_request_metrics.merge_request_id) > 1')
        .pluck(:merge_request_id)

      duplicated_merge_request_ids.each do |merge_request_id|
        deduplicate_item(merge_request_id)
      end
    end

    add_concurrent_index(:merge_request_metrics, :merge_request_id, unique: true, name: INDEX_NAME)
    remove_concurrent_index_by_name(:merge_request_metrics, TMP_INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:merge_request_metrics, TMP_INDEX_NAME)
    remove_concurrent_index_by_name(:merge_request_metrics, INDEX_NAME)
  end

  private

  def deduplicate_item(merge_request_id)
    merge_request_metrics_records = MergeRequestMetrics.where(merge_request_id: merge_request_id).order(updated_at: :asc).to_a

    attributes = {}
    merge_request_metrics_records.each do |merge_request_metrics_record|
      params = merge_request_metrics_record.attributes.except('id')
      attributes.merge!(params.compact)
    end

    ActiveRecord::Base.transaction do
      record_to_keep = merge_request_metrics_records.pop
      records_to_delete = merge_request_metrics_records

      MergeRequestMetrics.where(id: records_to_delete.map(&:id)).delete_all
      record_to_keep.update!(attributes)
    end
  end
end
