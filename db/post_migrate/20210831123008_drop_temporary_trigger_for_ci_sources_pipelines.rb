# frozen_string_literal: true

class DropTemporaryTriggerForCiSourcesPipelines < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  TABLE = 'ci_sources_pipelines'
  TEMPORARY_COLUMN = 'source_job_id_convert_to_bigint'
  MAIN_COLUMN = 'source_job_id'
  TRIGGER = 'trigger_8485e97c00e3'

  # rubocop:disable Migration/WithLockRetriesDisallowedMethod
  def up
    check_trigger_permissions!(TABLE)

    with_lock_retries do
      remove_rename_triggers(TABLE, TRIGGER)
    end
  end

  def down
    check_trigger_permissions!(TABLE)

    with_lock_retries do
      install_rename_triggers(TABLE, MAIN_COLUMN, TEMPORARY_COLUMN, trigger_name: TRIGGER)
    end
  end
  # rubocop:enable Migration/WithLockRetriesDisallowedMethod
end
