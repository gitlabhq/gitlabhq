# frozen_string_literal: true

class AddMachineIdToBuildsMetadata < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :p_ci_builds_metadata, :runner_machine_id, :bigint
  end
end
