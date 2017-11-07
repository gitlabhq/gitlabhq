class CreateProcessedLfsRefs < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    create_table :processed_lfs_refs do |t|
      t.references :project, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.datetime_with_timezone :updated_at, null: false
      t.string :ref, null: false
    end
  end
end
