# frozen_string_literal: true

class AddIndexesForMergeRequestDiffsQuery < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_SPECS = [
    [
      :merge_request_metrics,
      :latest_closed_at,
      { where: 'latest_closed_at IS NOT NULL' }
    ],
    [
      :merge_request_metrics,
      [:merge_request_id, :merged_at],
      { where: 'merged_at IS NOT NULL' }
    ],
    [
      :merge_request_diffs,
      [:merge_request_id, :id],
      {
        name: 'index_merge_request_diffs_on_merge_request_id_and_id_partial',
        where: 'NOT stored_externally OR stored_externally IS NULL'
      }
    ]
  ].freeze

  disable_ddl_transaction!

  def up
    INDEX_SPECS.each do |spec|
      add_concurrent_index(*spec)
    end
  end

  def down
    INDEX_SPECS.reverse_each do |spec|
      remove_concurrent_index(*spec)
    end
  end
end
