# frozen_string_literal: true

class CreateClusterEnabledGrants < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    create_table :cluster_enabled_grants do |t|
      t.references :namespace, index: { unique: true }, null: false, foreign_key: { on_delete: :cascade }
      t.datetime_with_timezone :created_at, null: false
    end
  end
end
