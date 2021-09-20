# frozen_string_literal: true

class EventsBigintConversionRemoveTriggers < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  TABLE_NAME = :events
  TRIGGER_NAME = :trigger_69523443cc10

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
      install_rename_triggers(TABLE_NAME, :id, :id_convert_to_bigint, trigger_name: TRIGGER_NAME)
    end
  end
  # rubocop:enable Migration/WithLockRetriesDisallowedMethod
end
