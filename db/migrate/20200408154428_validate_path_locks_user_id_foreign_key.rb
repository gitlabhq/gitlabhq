# frozen_string_literal: true

class ValidatePathLocksUserIdForeignKey < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  CONSTRAINT_NAME = 'fk_path_locks_user_id'

  def up
    validate_foreign_key :path_locks, :user_id, name: CONSTRAINT_NAME
  end

  def down
    # no op
  end
end
