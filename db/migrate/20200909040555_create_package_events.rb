# frozen_string_literal: true

class CreatePackageEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :packages_events do |t|
      t.integer :event_type, null: false, limit: 2
      t.integer :event_scope, null: false, limit: 2
      t.integer :originator_type, null: false, limit: 2
      t.bigint :originator
      t.datetime_with_timezone :created_at, null: false

      t.references :package, primary_key: false, default: nil, index: true, foreign_key: { to_table: :packages_packages, on_delete: :nullify }, type: :bigint
    end
  end
end
