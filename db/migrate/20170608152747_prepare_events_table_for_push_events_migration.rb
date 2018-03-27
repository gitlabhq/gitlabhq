# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class PrepareEventsTableForPushEventsMigration < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # The order of these columns is deliberate and results in the following
    # columns and sizes:
    #
    # * id (4 bytes)
    # * project_id (4 bytes)
    # * author_id (4 bytes)
    # * target_id (4 bytes)
    # * created_at (8 bytes)
    # * updated_at (8 bytes)
    # * action (2 bytes)
    # * target_type (variable)
    #
    # Unfortunately we can't make the "id" column a bigint/bigserial as Rails 4
    # does not support this properly.
    create_table :events_for_migration do |t|
      t.references :project,
                   index: true,
                   foreign_key: { on_delete: :cascade }

      t.integer :author_id, index: true, null: false
      t.integer :target_id

      t.timestamps_with_timezone null: false

      t.integer :action, null: false, limit: 2, index: true
      t.string :target_type

      t.index %i[target_type target_id]
    end

    # t.references doesn't like it when the column name doesn't make the table
    # name so we have to add the foreign key separately.
    add_concurrent_foreign_key(:events_for_migration, :users, column: :author_id)
  end

  def down
    drop_table :events_for_migration
  end
end
