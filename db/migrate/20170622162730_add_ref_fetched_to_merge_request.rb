class AddRefFetchedToMergeRequest < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :merge_requests, :ref_fetched, :boolean
  end
end
