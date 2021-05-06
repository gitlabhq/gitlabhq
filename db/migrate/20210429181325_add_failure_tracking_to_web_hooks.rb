# frozen_string_literal: true

class AddFailureTrackingToWebHooks < ActiveRecord::Migration[6.0]
  def change
    change_table(:web_hooks, bulk: true) do |t|
      t.integer :recent_failures, null: false, limit: 2, default: 0
      t.integer :backoff_count, null: false, limit: 2, default: 0
      t.column :disabled_until, :timestamptz
    end
  end
end
