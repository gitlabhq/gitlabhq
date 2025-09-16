# frozen_string_literal: true

class AddPersonalAccessTokenGranularScopesTable < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def change
    # rubocop:disable Migration/EnsureFactoryForTable -- False Positive
    create_table :personal_access_token_granular_scopes do |t|
      t.references :organization,
        foreign_key: { on_delete: :cascade },
        index: { name: 'idx_pat_granular_scopes_on_organization_id' },
        null: false
      t.references :personal_access_token,
        index: { name: 'idx_pat_granular_scopes_on_pat_id' },
        null: false
      t.references :granular_scope,
        foreign_key: { on_delete: :cascade },
        index: { name: 'idx_pat_granular_scopes_on_granular_scope_id' },
        null: false
    end
    # rubocop:enable Migration/EnsureFactoryForTable -- False Positive
  end
end
