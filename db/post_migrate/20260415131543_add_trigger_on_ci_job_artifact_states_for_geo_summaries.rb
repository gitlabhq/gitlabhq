# frozen_string_literal: true

class AddTriggerOnCiJobArtifactStatesForGeoSummaries < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  milestone '19.0'

  disable_ddl_transaction!

  FUNCTION_NAME = 'mark_geo_ci_job_artifact_verification_summary_dirty'
  TRIGGER_NAME = 'trigger_mark_geo_ci_job_artifact_summary_dirty'
  TABLE_NAME = :ci_job_artifact_states
  BUCKET_COUNT = 100_000

  def up
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{FUNCTION_NAME}()
        RETURNS TRIGGER
        LANGUAGE plpgsql
      AS $$
      DECLARE
        v_bucket_number integer;
        v_id bigint;
      BEGIN
        IF TG_OP = 'DELETE' THEN
          v_id := OLD.job_artifact_id;
        ELSE
          v_id := NEW.job_artifact_id;
        END IF;

        v_bucket_number := v_id % #{BUCKET_COUNT};

        INSERT INTO geo_ci_job_artifact_verification_summaries
          (bucket_number, state, state_changed_at, created_at, updated_at)
        VALUES
          (v_bucket_number, 1, NOW(), NOW(), NOW())
        ON CONFLICT (bucket_number)
        DO UPDATE SET
          state = 1,
          state_changed_at = NOW(),
          updated_at = NOW()
        WHERE geo_ci_job_artifact_verification_summaries.state != 2;

        RETURN NULL;
      END;
      $$;
    SQL

    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- Lock retries are recommended for trigger creation
    with_lock_retries do
      drop_trigger(TABLE_NAME, TRIGGER_NAME)

      execute(<<~SQL)
        CREATE TRIGGER #{TRIGGER_NAME}
        AFTER INSERT OR UPDATE OF verification_state OR DELETE ON #{TABLE_NAME}
        FOR EACH ROW
        EXECUTE FUNCTION #{FUNCTION_NAME}();
      SQL
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end

  def down
    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- Lock retries are recommended for trigger removal
    with_lock_retries do
      drop_trigger(TABLE_NAME, TRIGGER_NAME)
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod

    drop_function(FUNCTION_NAME)
  end
end
