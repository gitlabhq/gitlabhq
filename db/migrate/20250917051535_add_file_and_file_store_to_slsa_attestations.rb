# frozen_string_literal: true

class AddFileAndFileStoreToSlsaAttestations < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  def up
    with_lock_retries do
      add_column :slsa_attestations, :file, :text
      add_column :slsa_attestations, :file_store, :smallint, default: 1
    end

    add_text_limit :slsa_attestations, :file, 255
  end

  def down
    with_lock_retries do
      remove_column :slsa_attestations, :file
      remove_column :slsa_attestations, :file_store
    end
  end
end
