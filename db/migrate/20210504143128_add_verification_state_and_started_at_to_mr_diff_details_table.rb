# frozen_string_literal: true

class AddVerificationStateAndStartedAtToMrDiffDetailsTable < ActiveRecord::Migration[6.0]
  def change
    change_table(:merge_request_diff_details) do |t|
      t.integer :verification_state, default: 0, limit: 2, null: false
      t.column :verification_started_at, :datetime_with_timezone
    end
  end
end
