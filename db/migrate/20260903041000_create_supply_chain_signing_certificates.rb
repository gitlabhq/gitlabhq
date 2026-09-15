# frozen_string_literal: true

class CreateSupplyChainSigningCertificates < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    create_table :supply_chain_signing_certificates do |t|
      t.bigint :project_id, null: false
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :expires_at, null: false
      t.boolean :active, null: false, default: false
      t.jsonb :private_key, null: false
      t.text :certificate, null: false, limit: 3072

      t.check_constraint 'char_length(private_key::text) <= 12288',
        name: 'check_signing_certificates_private_key_size'
      t.index :project_id, name: 'index_supply_chain_signing_certificates_on_project_id'
      t.index :project_id, unique: true, where: 'active = true',
        name: 'uniq_idx_signing_certificates_on_project_id_when_active'
    end
  end
end
