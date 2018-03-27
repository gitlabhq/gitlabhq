# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreatePushEventPayloadsTables < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :push_event_payloads, id: false do |t|
      t.bigint :commit_count, null: false

      t.integer :event_id, null: false
      t.integer :action, null: false, limit: 2
      t.integer :ref_type, null: false, limit: 2

      t.binary :commit_from
      t.binary :commit_to

      t.text :ref
      t.string :commit_title, limit: 70

      t.index :event_id, unique: true
    end

    # We're adding a foreign key to the _shadow_ table, and this is deliberate.
    # By using the shadow table we don't have to recreate/revalidate this
    # foreign key after swapping the "events_for_migration" and "events" tables.
    #
    # The "events_for_migration" table has a foreign key to "projects.id"
    # ensuring that project removals also remove events from the shadow table
    # (and thus also from this table).
    add_concurrent_foreign_key(
      :push_event_payloads,
      :events_for_migration,
      column: :event_id
    )
  end

  def down
    drop_table :push_event_payloads
  end
end
