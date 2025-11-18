# frozen_string_literal: true

class PrepareAsyncCheckNotNullConstraintOnTodosShardingKey < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  CONSTRAINT_NAME = 'check_3c13ed1c7a'
  TABLE_NAME = :todos

  def up
    prepare_async_check_constraint_validation TABLE_NAME, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation TABLE_NAME, name: CONSTRAINT_NAME
  end
end
