class AddLockedToCiRunner < ActiveRecord::Migration
  ##
  # Downtime expected due to exclusive lock when setting default value.
  #
  def up
    add_column_with_default(:ci_runners, :locked, :boolean,
                            default: false, allow_null: false)
  end

  def down
    remove_column(:ci_runners, :locked)
  end
end
