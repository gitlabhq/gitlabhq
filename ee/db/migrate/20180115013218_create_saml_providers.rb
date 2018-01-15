class CreateSamlProviders < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :saml_providers do |t|
      t.references :group, null: false, index: true
      t.boolean :enabled, null: false
      t.string :certificate_fingerprint, null: false
      t.string :sso_url, null: false
    end

    add_foreign_key(:saml_providers, :namespaces, column: :group_id, on_delete: :cascade) # rubocop: disable Migration/AddConcurrentForeignKey
  end
end
