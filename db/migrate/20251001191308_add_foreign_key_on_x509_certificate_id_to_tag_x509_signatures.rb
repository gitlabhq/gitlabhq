# frozen_string_literal: true

class AddForeignKeyOnX509CertificateIdToTagX509Signatures < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :tag_x509_signatures, :x509_certificates, column: :x509_certificate_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :tag_x509_signatures, column: :x509_certificate_id
    end
  end
end
