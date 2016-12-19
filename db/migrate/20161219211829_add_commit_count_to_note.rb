class AddCommitCountToNote < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :notes, :commit_count, :integer, default: 0, allow_null: false
  end

  def down
    remove_column(:notes, :commit_count)
  end
end
