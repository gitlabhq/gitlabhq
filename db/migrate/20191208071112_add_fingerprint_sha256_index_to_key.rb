# frozen_string_literal: true

class AddFingerprintSha256IndexToKey < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:keys, "fingerprint_sha256")
  end

  def down
    remove_concurrent_index(:keys, "fingerprint_sha256")
  end
end
