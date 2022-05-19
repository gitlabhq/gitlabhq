# frozen_string_literal: true

class AddNamespaceCiCdSettingsTable < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    create_table :namespace_ci_cd_settings, id: false do |t|
      t.references :namespace, primary_key: true, default: nil, index: false, foreign_key: { on_delete: :cascade }
      t.boolean :allow_stale_runner_pruning, null: false, default: false
    end
  end

  def down
    drop_table :namespace_ci_cd_settings, if_exists: true
  end
end
