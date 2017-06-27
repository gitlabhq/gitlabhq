# rubocop:disable Migration/Timestamps
class CreateApproves < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :approvals do |t|
      t.integer :merge_request_id, null: false
      t.integer :user_id, null: false

      t.timestamps null: true
    end
  end
end
