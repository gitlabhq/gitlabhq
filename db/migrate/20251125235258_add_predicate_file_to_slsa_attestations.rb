# frozen_string_literal: true

class AddPredicateFileToSlsaAttestations < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    with_lock_retries do
      add_column :slsa_attestations, :predicate_file, :text
      add_column :slsa_attestations, :predicate_file_store, :smallint, default: 1, null: false
    end

    add_text_limit :slsa_attestations, :predicate_file, 1024
  end

  def down
    with_lock_retries do
      remove_column :slsa_attestations, :predicate_file
      remove_column :slsa_attestations, :predicate_file_store
    end
  end
end
