# frozen_string_literal: true

class CreateNamespaceSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      create_table :namespace_settings, id: false do |t|
        t.timestamps_with_timezone null: false
        t.references :namespace, primary_key: true, default: nil, type: :integer, index: false, foreign_key: { on_delete: :cascade }
      end
    end
  end

  def down
    drop_table :namespace_settings
  end
end
