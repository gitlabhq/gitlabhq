# frozen_string_literal: true

class AddNamespaceFkToObservabilityProjectO11ySettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.4'

  def up
    # Handled by Namespace#observability_project_o11y_settings association (cascade at DB level).
    # No application callbacks needed - rows are plain settings with no side effects.
    add_concurrent_foreign_key :observability_project_o11y_settings, :namespaces, # rubocop:disable Migration/ForeignKeysToDestroyServiceTables -- cascade at DB level, no application callbacks needed
      column: :namespace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :observability_project_o11y_settings, column: :namespace_id
    end
  end
end
