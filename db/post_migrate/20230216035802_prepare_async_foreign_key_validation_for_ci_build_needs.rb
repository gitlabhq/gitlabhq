# frozen_string_literal: true

class PrepareAsyncForeignKeyValidationForCiBuildNeeds < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_build_needs
  COLUMN_NAMES = [:partition_id, :build_id]
  FOREIGN_KEY_NAME = :fk_rails_3cf221d4ed_p

  def up
    prepare_async_foreign_key_validation(TABLE_NAME, COLUMN_NAMES, name: FOREIGN_KEY_NAME)
  end

  def down
    unprepare_async_foreign_key_validation(TABLE_NAME, COLUMN_NAMES, name: FOREIGN_KEY_NAME)
  end
end
