# frozen_string_literal: true

class PushEventPayloadsBigintConversionRemoveTriggers < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  TABLE_NAME = :push_event_payloads
  TRIGGER_NAME = 'trigger_07c94931164e'

  # rubocop:disable Migration/WithLockRetriesDisallowedMethod
  def up
    check_trigger_permissions!(TABLE_NAME)

    with_lock_retries do
      remove_rename_triggers(TABLE_NAME, TRIGGER_NAME)
    end
  end

  def down
    check_trigger_permissions!(TABLE_NAME)

    with_lock_retries do
      install_rename_triggers(TABLE_NAME, :event_id, :event_id_convert_to_bigint, trigger_name: TRIGGER_NAME)
    end
  end
  # rubocop:enable Migration/WithLockRetriesDisallowedMethod
end
