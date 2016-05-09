class AddLockedToCiRunner < ActiveRecord::Migration
  ##
  # Downtime expected due to exclusive lock when setting default value.
  #
  def change
    add_column :ci_runners, :locked, :boolean, default: false, null: false
  end
end
