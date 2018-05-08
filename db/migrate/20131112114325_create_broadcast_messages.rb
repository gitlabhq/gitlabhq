# rubocop:disable all
class CreateBroadcastMessages < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :broadcast_messages do |t|
      t.text :message, null: false
      t.datetime :starts_at
      t.datetime :ends_at
      t.integer :alert_type

      t.timestamps null: true
    end
  end
end
