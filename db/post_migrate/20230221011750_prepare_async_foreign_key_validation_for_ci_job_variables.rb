# frozen_string_literal: true

class PrepareAsyncForeignKeyValidationForCiJobVariables < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_job_variables
  COLUMN_NAMES = [:partition_id, :job_id]
  FOREIGN_KEY_NAME = :fk_rails_fbf3b34792_p

  def up
    prepare_async_foreign_key_validation(TABLE_NAME, COLUMN_NAMES, name: FOREIGN_KEY_NAME)
  end

  def down
    unprepare_async_foreign_key_validation(TABLE_NAME, COLUMN_NAMES, name: FOREIGN_KEY_NAME)
  end
end
