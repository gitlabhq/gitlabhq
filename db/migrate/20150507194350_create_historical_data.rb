class CreateHistoricalData < ActiveRecord::Migration
  def change
    create_table :historical_data do |t|
      t.date :date, null: false
      t.integer :active_user_count

      t.timestamps
    end
  end
end
