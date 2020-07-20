# frozen_string_literal: true

class CreateNamespaceLimits < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      create_table :namespace_limits, id: false do |t|
        t.bigint :additional_purchased_storage_size, default: 0, null: false
        t.date :additional_purchased_storage_ends_on, null: true

        t.references :namespace, primary_key: true, default: nil, type: :integer, index: false, foreign_key: { on_delete: :cascade }
      end
    end
  end

  def down
    drop_table :namespace_limits
  end
end
