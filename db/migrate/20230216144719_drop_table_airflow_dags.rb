# frozen_string_literal: true

class DropTableAirflowDags < Gitlab::Database::Migration[2.1]
  def up
    # the table is not in use
    drop_table :airflow_dags, if_exists: true # rubocop: disable Migration/DropTable
  end

  def down
    create_table :airflow_dags do |t|
      t.references :project, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :next_run
      t.boolean :has_import_errors
      t.boolean :is_active
      t.boolean :is_paused
      t.text :dag_name, null: false, limit: 255
      t.text :schedule, limit: 255
      t.text :fileloc, limit: 255
    end
  end
end
