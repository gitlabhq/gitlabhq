# frozen_string_literal: true

class DropPackagesEventsTable < Gitlab::Database::Migration[2.1]
  def up
    drop_table :packages_events, if_exists: true
  end

  def down
    return if table_exists?(:packages_events)

    create_table :packages_events do |t| # rubocop:disable Migration/SchemaAdditionMethodsNoPost
      t.integer :event_type, limit: 2, null: false
      t.integer :event_scope, limit: 2, null: false
      t.integer :originator_type, limit: 2, null: false
      t.bigint :originator
      t.datetime_with_timezone :created_at, null: false
      t.references :package,
        index: true,
        foreign_key: { to_table: :packages_packages, on_delete: :nullify },
        type: :bigint
    end
  end
end
