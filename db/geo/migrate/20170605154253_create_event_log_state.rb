class CreateEventLogState < ActiveRecord::Migration
  def change
    create_table :event_log_states, id: false do |t|
      t.primary_key :event_id, :bigserial
    end
  end
end
