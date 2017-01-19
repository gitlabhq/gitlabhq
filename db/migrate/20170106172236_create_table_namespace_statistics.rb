class CreateTableNamespaceStatistics < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :namespace_statistics do |t|
      t.references :namespace, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.integer :shared_runners_seconds, default: 0, null: false
      t.timestamp :shared_runners_seconds_last_reset
    end
  end
end
