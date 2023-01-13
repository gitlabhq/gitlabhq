# frozen_string_literal: true

class AddFingerprintToSshSignatures < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_column :ssh_signatures, :key_fingerprint_sha256, :bytea, if_not_exists: true
  end

  def down
    remove_column :ssh_signatures, :key_fingerprint_sha256, :bytea, if_exists: true
  end
end
