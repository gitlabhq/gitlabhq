# frozen_string_literal: true

class AddGranularScopesTable < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def change
    # rubocop:disable Migration/EnsureFactoryForTable -- False Positive
    create_table :granular_scopes do |t|
      t.references :organization,
        foreign_key: { on_delete: :cascade },
        index: { name: 'idx_granular_scopes_on_organization_id' },
        null: false
      t.references :namespace,
        index: { name: 'idx_granular_scopes_on_namespace_id' }
      t.timestamps_with_timezone
      t.jsonb :permissions, default: [], null: false
      t.check_constraint "jsonb_typeof(permissions) = 'array'", name: 'check_permissions_is_array'
    end
    # rubocop:enable Migration/EnsureFactoryForTable -- False Positive
  end
end
