class CreateUnprocessedLfsPushes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    create_table :unprocessed_lfs_pushes do |t|
      t.references :project, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.string :ref, null: false
    end
  end
end
