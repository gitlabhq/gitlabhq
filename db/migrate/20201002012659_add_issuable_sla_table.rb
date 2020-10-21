# frozen_string_literal: true

class AddIssuableSlaTable < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :issuable_slas do |t|
      t.references :issue, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.datetime_with_timezone :due_at, null: false
    end
  end
end
