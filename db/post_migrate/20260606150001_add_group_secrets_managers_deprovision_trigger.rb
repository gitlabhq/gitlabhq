# frozen_string_literal: true

class AddGroupSecretsManagersDeprovisionTrigger < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  milestone '19.2'

  FUNCTION_NAME = 'enqueue_gsm_deprovision_task'
  TRIGGER_NAME = 'enqueue_gsm_deprovision_task_after_delete'

  # `action = 1` matches the Rails enum on
  # SecretsManagement::BaseSecretsManagerMaintenanceTask (provision: 0,
  # deprovision: 1). Hardcoded here because PG triggers cannot read
  # Ruby enums. If the enum ever changes, this trigger must change too.
  ACTION_DEPROVISION = 1

  # `last_processed_at` is intentionally left NULL on rows we insert
  # here. The `:stale` scope on BaseSecretsManagerMaintenanceTask treats
  # NULL as eligible, so the next cron tick picks the row up. The Ruby
  # services that create tasks set this to NOW() to suppress redundant
  # cron pickup while their `perform_async` runs; that protection is
  # irrelevant here because the trigger has no synchronous enqueue.
  #
  # `CREATE TRIGGER` acquires SHARE ROW EXCLUSIVE on the SM table,
  # conflicting with the ROW EXCLUSIVE that regular INSERT/UPDATE/DELETE
  # holds. We don't wrap in `with_lock_retries` because the rubocop
  # `Migration/WithLockRetriesDisallowedMethod` cop rejects
  # `create_trigger` / `drop_trigger` in that block. Implicit lock
  # retry from the migration's enclosing transaction still applies
  # (regular migrations have lock-retry enabled by default unless
  # `disable_ddl_transaction!` is set).
  def up
    create_trigger_function(FUNCTION_NAME, replace: true) do
      <<~SQL
        IF OLD.group_id IS NULL THEN
          RETURN NULL;
        END IF;

        INSERT INTO group_secrets_manager_maintenance_tasks (
          action,
          retry_count,
          organization_id,
          group_id,
          root_namespace_id
        ) VALUES (
          #{ACTION_DEPROVISION},
          0,
          OLD.organization_id,
          OLD.group_id,
          OLD.root_namespace_id
        )
        ON CONFLICT (group_id) DO NOTHING;

        RETURN NULL;
      SQL
    end

    create_trigger(
      :group_secrets_managers,
      TRIGGER_NAME,
      FUNCTION_NAME,
      fires: 'AFTER DELETE'
    )
  end

  def down
    drop_trigger(:group_secrets_managers, TRIGGER_NAME)
    drop_function(FUNCTION_NAME)
  end
end
