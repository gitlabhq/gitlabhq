# frozen_string_literal: true

class AddRetriesLeftToZoektRepository < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  disable_ddl_transaction!
  CONSTRAINT_NAME = 'c_zoekt_repositories_on_retries_left'
  FAILED_STATE_ENUM = 200 # We are assuming that all problematic states are >= 200
  CONSTRAINT_QUERY = <<~SQL
    (retries_left > 0) OR (retries_left = 0 AND state >= #{FAILED_STATE_ENUM})
  SQL

  def up
    with_lock_retries do
      add_column :zoekt_repositories, :retries_left, :integer, limit: 2, default: 10, null: false, if_not_exists: true
    end

    add_check_constraint :zoekt_repositories, CONSTRAINT_QUERY, CONSTRAINT_NAME
  end

  def down
    with_lock_retries do
      remove_column :zoekt_repositories, :retries_left, if_exists: true
    end
  end
end
