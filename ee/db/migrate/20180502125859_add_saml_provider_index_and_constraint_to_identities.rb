class AddSamlProviderIndexAndConstraintToIdentities < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :identities, :saml_provider_id, where: 'saml_provider_id IS NOT NULL'
    add_concurrent_foreign_key :identities, :saml_providers, column: :saml_provider_id, on_delete: :cascade
  end

  def down
    remove_foreign_key :identities, column: :saml_provider_id
    remove_concurrent_index :identities, :saml_provider_id
  end
end
