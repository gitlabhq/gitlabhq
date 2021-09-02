# frozen_string_literal: true

class DropTemporaryTriggerForCiJobArtifacts < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  TABLE = 'ci_job_artifacts'
  TEMPORARY_COLUMNS = %w(id_convert_to_bigint job_id_convert_to_bigint)
  MAIN_COLUMNS = %w(id job_id)
  TRIGGER = 'trigger_be1804f21693'

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
      install_rename_triggers(TABLE, MAIN_COLUMNS, TEMPORARY_COLUMNS, trigger_name: TRIGGER)
    end
  end
  # rubocop:enable Migration/WithLockRetriesDisallowedMethod
end
