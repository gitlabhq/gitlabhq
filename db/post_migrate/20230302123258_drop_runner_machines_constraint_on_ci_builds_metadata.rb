# frozen_string_literal: true

class DropRunnerMachinesConstraintOnCiBuildsMetadata < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = 'p_ci_builds_metadata'
  TARGET_TABLE_NAME = 'ci_runner_machines'
  CONSTRAINT_NAME = 'fk_rails_fae01b2700'

  def up
    with_lock_retries(raise_on_exhaustion: true) do
      remove_foreign_key_if_exists(SOURCE_TABLE_NAME, TARGET_TABLE_NAME, name: CONSTRAINT_NAME)
    end
  end

  def down
    with_lock_retries(raise_on_exhaustion: true) do
      next if check_constraint_exists?(SOURCE_TABLE_NAME, CONSTRAINT_NAME)

      execute(<<~SQL)
        ALTER TABLE #{SOURCE_TABLE_NAME}
        ADD CONSTRAINT #{CONSTRAINT_NAME} FOREIGN KEY (runner_machine_id)
          REFERENCES #{TARGET_TABLE_NAME}(id) ON DELETE SET NULL
      SQL
    end
  end
end
