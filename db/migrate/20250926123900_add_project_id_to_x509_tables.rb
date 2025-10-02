# frozen_string_literal: true

class AddProjectIdToX509Tables < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :x509_issuers, :project_id, :bigint, if_not_exists: true
    end

    with_lock_retries do
      add_column :x509_certificates, :project_id, :bigint, if_not_exists: true
    end
  end

  def down
    with_lock_retries do
      remove_column :x509_issuers, :project_id, if_exists: true
    end

    with_lock_retries do
      remove_column :x509_certificates, :project_id, if_exists: true
    end
  end
end
