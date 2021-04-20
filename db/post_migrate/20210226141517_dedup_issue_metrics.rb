# frozen_string_literal: true

class DedupIssueMetrics < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  TMP_INDEX_NAME = 'tmp_unique_issue_metrics_by_issue_id'
  OLD_INDEX_NAME = 'index_issue_metrics'
  INDEX_NAME = 'index_unique_issue_metrics_issue_id'
  BATCH_SIZE = 1_000

  disable_ddl_transaction!

  class IssueMetrics < ActiveRecord::Base
    self.table_name = 'issue_metrics'

    include EachBatch
  end

  def up
    IssueMetrics.reset_column_information

    last_metrics_record_id = IssueMetrics.maximum(:id) || 0

    # This index will disallow further duplicates while we're deduplicating the data.
    add_concurrent_index(:issue_metrics, :issue_id, where: "id > #{Integer(last_metrics_record_id)}", unique: true, name: TMP_INDEX_NAME)

    IssueMetrics.each_batch(of: BATCH_SIZE) do |relation|
      duplicated_issue_ids = IssueMetrics
        .where(issue_id: relation.select(:issue_id))
        .select(:issue_id)
        .group(:issue_id)
        .having('COUNT(issue_metrics.issue_id) > 1')
        .pluck(:issue_id)

      duplicated_issue_ids.each do |issue_id|
        deduplicate_item(issue_id)
      end
    end

    add_concurrent_index(:issue_metrics, :issue_id, unique: true, name: INDEX_NAME)
    remove_concurrent_index_by_name(:issue_metrics, TMP_INDEX_NAME)
    remove_concurrent_index_by_name(:issue_metrics, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(:issue_metrics, :issue_id, name: OLD_INDEX_NAME)
    remove_concurrent_index_by_name(:issue_metrics, TMP_INDEX_NAME)
    remove_concurrent_index_by_name(:issue_metrics, INDEX_NAME)
  end

  private

  def deduplicate_item(issue_id)
    issue_metrics_records = IssueMetrics.where(issue_id: issue_id).order(updated_at: :asc).to_a

    attributes = {}
    issue_metrics_records.each do |issue_metrics_record|
      params = issue_metrics_record.attributes.except('id')
      attributes.merge!(params.compact)
    end

    ActiveRecord::Base.transaction do
      record_to_keep = issue_metrics_records.pop
      records_to_delete = issue_metrics_records

      IssueMetrics.where(id: records_to_delete.map(&:id)).delete_all
      record_to_keep.update!(attributes)
    end
  end
end
