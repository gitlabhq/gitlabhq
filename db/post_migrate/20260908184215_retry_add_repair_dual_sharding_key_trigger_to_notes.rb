# frozen_string_literal: true

# Reintroduces the BEFORE UPDATE repair trigger from the no-oped 20260902151429
# original (nulls namespace_id on dual-key notes rows). Idempotent: safe where
# the original succeeded. https://gitlab.com/gitlab-org/gitlab/-/work_items/627843
class RetryAddRepairDualShardingKeyTriggerToNotes < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  milestone '19.4'

  disable_ddl_transaction!

  FUNCTION_NAME = 'repair_dual_sharding_key_on_notes'
  TRIGGER_NAME = 'trigger_817aa51bc4f2'
  TABLE_NAME = :notes

  def up
    # Raise rather than skip: a skipped run is recorded as executed, which is how
    # gprd lost the trigger in the first place.
    unless can_execute_on?(TABLE_NAME)
      raise StandardError,
        "Wraparound prevention vacuum detected on the notes table. Please try again later."
    end

    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- recommended for
    # trigger creation on notes, a high-traffic table
    with_lock_retries do
      create_trigger_function(FUNCTION_NAME, replace: true) do
        <<~SQL
          NEW.namespace_id := NULL;

          RETURN NEW;
        SQL
      end

      drop_trigger(TABLE_NAME, TRIGGER_NAME)
      create_trigger(TABLE_NAME, TRIGGER_NAME, FUNCTION_NAME, fires: 'BEFORE UPDATE') do
        'WHEN (NEW.namespace_id IS NOT NULL AND NEW.project_id IS NOT NULL)'
      end
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end

  # No-op: both objects are already in db/structure.sql via 20260902151429, so
  # dropping them here would make a rollback diverge from the recorded schema.
  def down; end
end
