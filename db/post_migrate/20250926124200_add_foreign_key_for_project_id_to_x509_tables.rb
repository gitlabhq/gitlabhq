# frozen_string_literal: true

class AddForeignKeyForProjectIdToX509Tables < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :x509_issuers, :projects, column: :project_id, on_delete: :cascade
    add_concurrent_foreign_key :x509_certificates, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :x509_issuers, column: :project_id
    end

    with_lock_retries do
      remove_foreign_key :x509_certificates, column: :project_id
    end
  end
end
