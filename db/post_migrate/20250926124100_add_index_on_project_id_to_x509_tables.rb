# frozen_string_literal: true

class AddIndexOnProjectIdToX509Tables < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  disable_ddl_transaction!

  INDEX_NAME_ISSUERS = 'index_x509_issuers_on_project_id'
  INDEX_NAME_CERTIFICATES = 'index_x509_certificates_on_project_id'

  def up
    add_concurrent_index :x509_issuers, :project_id, name: INDEX_NAME_ISSUERS
    add_concurrent_index :x509_certificates, :project_id, name: INDEX_NAME_CERTIFICATES
  end

  def down
    remove_concurrent_index_by_name :x509_issuers, INDEX_NAME_ISSUERS
    remove_concurrent_index_by_name :x509_certificates, INDEX_NAME_CERTIFICATES
  end
end
