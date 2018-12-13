# frozen_string_literal: true

class CreateProjectDailyStatistics < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :project_daily_statistics, id: :bigserial do |t|
      t.integer :project_id, null: false
      t.integer :fetch_count, null: false
      t.date :date

      t.index [:project_id, :date], unique: true, order: { date: :desc }
      t.foreign_key :projects, on_delete: :cascade
    end
  end
end
