# frozen_string_literal: true

class CreateIterationsCadence < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table_with_constraints :iterations_cadences do |t|
      t.references :group, null: false, foreign_key: { to_table: :namespaces, on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.date :start_date, null: false
      t.date :last_run_date
      t.integer :duration_in_weeks
      t.integer :iterations_in_advance
      t.boolean :active, default: true, null: false
      t.boolean :automatic, default: true, null: false
      t.text :title, null: false

      t.text_limit :title, 255
    end
  end

  def down
    drop_table :iterations_cadences if table_exists?(:iterations_cadences)
  end
end
