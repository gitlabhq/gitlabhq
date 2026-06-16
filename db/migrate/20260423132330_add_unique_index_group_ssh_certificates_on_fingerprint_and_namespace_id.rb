# frozen_string_literal: true

class AddUniqueIndexGroupSshCertificatesOnFingerprintAndNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_group_ssh_certificates_on_fingerprint'
  NEW_INDEX_NAME = 'index_group_ssh_certificates_on_fingerprint_and_namespace_id'

  def up
    add_concurrent_index :group_ssh_certificates, %i[fingerprint namespace_id], unique: true, name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :group_ssh_certificates, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :group_ssh_certificates, :fingerprint, unique: true, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :group_ssh_certificates, NEW_INDEX_NAME
  end
end
