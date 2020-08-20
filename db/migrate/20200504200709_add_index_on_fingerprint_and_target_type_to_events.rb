# frozen_string_literal: true

class AddIndexOnFingerprintAndTargetTypeToEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  KEYS = [:target_type, :target_id, :fingerprint]

  def up
    add_concurrent_index :events, KEYS, using: :btree, unique: true
  end

  def down
    remove_concurrent_index :events, KEYS
  end
end
