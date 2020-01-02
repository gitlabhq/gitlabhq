# frozen_string_literal: true

class CreateResourceWeightEvent < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :resource_weight_events do |t|
      t.references :user, null: false, foreign_key: { on_delete: :nullify },
                   index: { name: 'index_resource_weight_events_on_user_id' }
      t.references :issue, null: false, foreign_key: { on_delete: :cascade },
                   index: false
      t.integer :weight
      t.datetime_with_timezone :created_at, null: false

      t.index [:issue_id, :weight], name: 'index_resource_weight_events_on_issue_id_and_weight'
    end
  end
end
