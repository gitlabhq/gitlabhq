# frozen_string_literal: true

class CreateSubscriptionAddOns < Gitlab::Database::Migration[2.1]
  def change
    create_table :subscription_add_ons, if_not_exists: true do |t|
      t.timestamps_with_timezone null: false

      t.integer :name, limit: 2, null: false, index: { unique: true }
      t.text    :description, null: false, limit: 512
    end
  end
end
