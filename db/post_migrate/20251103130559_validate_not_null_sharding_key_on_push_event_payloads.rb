# frozen_string_literal: true

class ValidateNotNullShardingKeyOnPushEventPayloads < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  CONSTRAINT_NAME = :check_37c617d07d

  def up
    validate_not_null_constraint :push_event_payloads, :project_id, constraint_name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
