class CreateEventLogState < ActiveRecord::Migration
  def change
    create_table :event_log_states, id: false do |t|
      t.integer :event_id, limit: 8, primary_key: true
    end
  end
end
