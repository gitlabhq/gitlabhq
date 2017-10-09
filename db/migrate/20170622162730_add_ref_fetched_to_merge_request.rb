class AddRefFetchedToMergeRequest < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :merge_requests, :ref_fetched, :boolean
  end
end
