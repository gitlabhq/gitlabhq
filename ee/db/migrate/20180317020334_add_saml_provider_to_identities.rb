class AddSamlProviderToIdentities < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def change
    add_column :identities, :saml_provider_id, :integer
  end
end
