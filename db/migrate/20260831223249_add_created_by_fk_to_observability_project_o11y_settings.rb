# frozen_string_literal: true

class AddCreatedByFkToObservabilityProjectO11ySettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.4'

  def up
    # Handled by User#observability_project_o11y_settings (dependent: :nullify) via Users::DestroyService.
    add_concurrent_foreign_key :observability_project_o11y_settings, :users, # rubocop:disable Migration/ForeignKeysToDestroyServiceTables -- handled by User association (dependent: :nullify)
      column: :created_by_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :observability_project_o11y_settings, column: :created_by_id
    end
  end
end
