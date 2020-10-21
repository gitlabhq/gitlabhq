# frozen_string_literal: true

class CreateCiDeletedObjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :ci_deleted_objects, if_not_exists: true do |t|
      t.integer :file_store, limit: 2, default: 1, null: false
      t.datetime_with_timezone :pick_up_at, null: false, default: -> { 'now()' }, index: true
      t.text :store_dir, null: false

      # rubocop:disable Migration/AddLimitToTextColumns
      # This column depends on the `file` column from `ci_job_artifacts` table
      # which doesn't have a constraint limit on it.
      t.text :file, null: false
      # rubocop:enable Migration/AddLimitToTextColumns
    end

    add_text_limit(:ci_deleted_objects, :store_dir, 1024)
  end

  def down
    drop_table :ci_deleted_objects
  end
end
