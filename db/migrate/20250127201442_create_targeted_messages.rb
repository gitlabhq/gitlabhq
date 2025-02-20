# frozen_string_literal: true

class CreateTargetedMessages < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    create_table :targeted_messages do |t|
      t.timestamps_with_timezone null: false
      t.integer :target_type, null: false, default: 0, limit: 2
    end
  end
end
