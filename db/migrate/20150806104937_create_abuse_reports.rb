class CreateAbuseReports < ActiveRecord::Migration
  def change
    create_table :abuse_reports do |t|
      t.integer :reporter_id
      t.integer :user_id
      t.text :message

      t.timestamps
    end
  end
end
