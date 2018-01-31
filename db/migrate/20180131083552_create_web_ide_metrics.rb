class CreateWebIdeMetrics < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :web_ide_metrics do |t|
      t.string :project, null: false, limit: 64
      t.string :user, null: false, limit: 64
      t.integer :line_count, null: false
      t.integer :file_count, null: false

      t.datetime_with_timezone :created_at
    end
  end
end
