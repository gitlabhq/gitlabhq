# frozen_string_literal: true

class CreateIssuableSeverities < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      create_table :issuable_severities do |t|
        t.references :issue, index: { unique: true }, null: false, foreign_key: { on_delete: :cascade }
        t.integer :severity, null: false, default: 0, limit: 2 # 0 - will stand for unknown
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :issuable_severities
    end
  end
end
