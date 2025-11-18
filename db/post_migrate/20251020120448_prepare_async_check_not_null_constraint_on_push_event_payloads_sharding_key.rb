# frozen_string_literal: true

class PrepareAsyncCheckNotNullConstraintOnPushEventPayloadsShardingKey < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  CONSTRAINT_NAME = 'check_37c617d07d'
  TABLE_NAME = :push_event_payloads

  def up
    prepare_async_check_constraint_validation TABLE_NAME, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation TABLE_NAME, name: CONSTRAINT_NAME
  end
end
