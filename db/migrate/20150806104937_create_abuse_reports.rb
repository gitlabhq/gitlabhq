# rubocop:disable all
class CreateAbuseReports < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :abuse_reports do |t|
      t.integer :reporter_id
      t.integer :user_id
      t.text :message

      t.timestamps null: true
    end
  end
end
