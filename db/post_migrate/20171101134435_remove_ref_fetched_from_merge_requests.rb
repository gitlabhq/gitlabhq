class RemoveRefFetchedFromMergeRequests < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # We don't need to cache this anymore: the refs are now created
  # upon save/update and there is no more use for this flag
  #
  # See https://gitlab.com/gitlab-org/gitlab-ce/issues/36061
  def change
    remove_column :merge_requests, :ref_fetched, :boolean
  end
end
