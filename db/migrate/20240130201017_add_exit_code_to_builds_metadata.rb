# frozen_string_literal: true

class AddExitCodeToBuildsMetadata < Gitlab::Database::Migration[2.2]
  enable_lock_retries!

  milestone '16.10'

  def change
    add_column :p_ci_builds_metadata, :exit_code, :smallint, null: true
  end
end
