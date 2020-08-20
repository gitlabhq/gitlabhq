# frozen_string_literal: true

class AddFingerprintToEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless column_exists?(:events, :fingerprint)
      with_lock_retries { add_column :events, :fingerprint, :binary }
    end

    unless check_constraint_exists?(:events, constraint_name)
      add_check_constraint(
        :events,
        "octet_length(fingerprint) <= 128",
        constraint_name,
        validate: true
      )
    end
  end

  def down
    remove_check_constraint(:events, constraint_name)

    if column_exists?(:events, :fingerprint)
      with_lock_retries { remove_column :events, :fingerprint }
    end
  end

  def constraint_name
    check_constraint_name(:events, :fingerprint, 'max_length')
  end
end
