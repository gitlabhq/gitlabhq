# frozen_string_literal: true

class AddTextLimitsToContainerRepositoriesMigrationColumns < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :container_repositories, :migration_state, 255
    add_text_limit :container_repositories, :migration_aborted_in_state, 255
  end

  def down
    remove_text_limit :container_repositories, :migration_state
    remove_text_limit :container_repositories, :migration_aborted_in_state
  end
end
