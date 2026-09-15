# frozen_string_literal: true

class AddSigningCertificateIdToSlsaAttestations < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.4'

  INDEX_NAME = 'index_slsa_attestations_on_signing_certificate_id'
  TABLE = :slsa_attestations

  def up
    with_lock_retries do
      add_column TABLE, :signing_certificate_id, :bigint, null: true, if_not_exists: true
    end

    add_concurrent_index TABLE, :signing_certificate_id, name: INDEX_NAME
    add_concurrent_foreign_key TABLE, :supply_chain_signing_certificates,
      column: :signing_certificate_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_column TABLE, :signing_certificate_id, :bigint, null: true, if_exists: true
    end
  end
end
