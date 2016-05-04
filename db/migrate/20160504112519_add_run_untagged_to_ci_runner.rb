class AddRunUntaggedToCiRunner < ActiveRecord::Migration
  ##
  # Downtime expected!
  #
  # This migration will cause downtime due to exclusive lock
  # caused by the default value.
  #
  def change
    add_column :ci_runners, :run_untagged, :boolean, default: true
  end
end
