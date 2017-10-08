class AddLockedToCiRunner < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  def up
    add_column_with_default(:ci_runners, :locked, :boolean,
                            default: false, allow_null: false)
  end

  def down
    remove_column(:ci_runners, :locked)
  end
end
