# frozen_string_literal: true

class CreateTriggersForCiPipelineIids < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  milestone '18.7'

  disable_ddl_transaction!

  BEFORE_INSERT_FUNCTION_NAME = 'ensure_pipeline_iid_uniqueness_before_insert'
  BEFORE_UPDATE_IID_FUNCTION_NAME = 'ensure_pipeline_iid_uniqueness_before_update_iid'
  AFTER_DELETE_FUNCTION_NAME = 'cleanup_pipeline_iid_after_delete'

  BEFORE_INSERT_TRIGGER_NAME = "trigger_#{BEFORE_INSERT_FUNCTION_NAME}"
  BEFORE_UPDATE_IID_TRIGGER_NAME = "trigger_#{BEFORE_UPDATE_IID_FUNCTION_NAME}"
  AFTER_DELETE_TRIGGER_NAME = "trigger_#{AFTER_DELETE_FUNCTION_NAME}"

  def up
    # Function: inserts a new iid record before a pipeline record is inserted
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{BEFORE_INSERT_FUNCTION_NAME}()
        RETURNS TRIGGER
        LANGUAGE plpgsql
      AS $$
      BEGIN
        IF NEW.iid IS NOT NULL THEN
          BEGIN
            INSERT INTO p_ci_pipeline_iids (project_id, iid)
            VALUES (NEW.project_id, NEW.iid);
          EXCEPTION WHEN unique_violation THEN
            RAISE EXCEPTION 'Pipeline with iid % already exists for project %',
              NEW.iid, NEW.project_id
              USING ERRCODE = 'unique_violation',
                    DETAIL = 'The iid must be unique within a project',
                    HINT = 'Use a different iid or let the system generate one';
          END;
        END IF;

        RETURN NEW;
      END;
      $$;
    SQL

    # Function: before the iid of a pipeline record is updated (and is a new value),
    # adds the new iid record and deletes the old iid record.
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{BEFORE_UPDATE_IID_FUNCTION_NAME}()
        RETURNS TRIGGER
        LANGUAGE plpgsql
      AS $$
      BEGIN
        IF NEW.iid IS DISTINCT FROM OLD.iid THEN
          IF NEW.iid IS NOT NULL THEN
            BEGIN
              INSERT INTO p_ci_pipeline_iids (project_id, iid)
              VALUES (NEW.project_id, NEW.iid);
            EXCEPTION WHEN unique_violation THEN
              RAISE EXCEPTION 'Pipeline with iid % already exists for project %',
                NEW.iid, NEW.project_id
                USING ERRCODE = 'unique_violation',
                      DETAIL = 'The iid must be unique within a project',
                      HINT = 'Use a different iid or let the system generate one';
            END;
          END IF;

          IF OLD.iid IS NOT NULL THEN
            DELETE FROM p_ci_pipeline_iids
            WHERE project_id = OLD.project_id AND iid = OLD.iid;
          END IF;
        END IF;
        RETURN NEW;
      END;
      $$;
    SQL

    # Function: deletes the iid record after the pipeline record is deleted
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{AFTER_DELETE_FUNCTION_NAME}()
        RETURNS TRIGGER
        LANGUAGE plpgsql
      AS $$
      BEGIN
        IF OLD.iid IS NOT NULL THEN
          DELETE FROM p_ci_pipeline_iids
          WHERE project_id = OLD.project_id AND iid = OLD.iid;
        END IF;
        RETURN OLD;
      END;
      $$;
    SQL

    # Clean up the triggers if they already exist on p_ci_pipelines
    # rubocop: disable Migration/WithLockRetriesDisallowedMethod -- Lock retries are recommended
    # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188143#note_2493525239
    with_lock_retries do
      drop_trigger(:p_ci_pipelines, BEFORE_INSERT_TRIGGER_NAME)
      drop_trigger(:p_ci_pipelines, BEFORE_UPDATE_IID_TRIGGER_NAME)
      drop_trigger(:p_ci_pipelines, AFTER_DELETE_TRIGGER_NAME)
    end
    # rubocop: enable Migration/WithLockRetriesDisallowedMethod

    # Create triggers on p_ci_pipelines
    with_lock_retries do
      execute(<<~SQL)
        CREATE TRIGGER #{BEFORE_INSERT_TRIGGER_NAME}
        BEFORE INSERT ON p_ci_pipelines
        FOR EACH ROW
        EXECUTE FUNCTION #{BEFORE_INSERT_FUNCTION_NAME}();

        CREATE TRIGGER #{BEFORE_UPDATE_IID_TRIGGER_NAME}
        BEFORE UPDATE OF iid ON p_ci_pipelines
        FOR EACH ROW
        EXECUTE FUNCTION #{BEFORE_UPDATE_IID_FUNCTION_NAME}();

        CREATE TRIGGER #{AFTER_DELETE_TRIGGER_NAME}
        AFTER DELETE ON p_ci_pipelines
        FOR EACH ROW
        EXECUTE FUNCTION #{AFTER_DELETE_FUNCTION_NAME}();
      SQL
    end
  end

  def down
    # rubocop: disable Migration/WithLockRetriesDisallowedMethod -- Lock retries are recommended
    # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188143#note_2493525239
    with_lock_retries do
      drop_trigger(:p_ci_pipelines, BEFORE_INSERT_TRIGGER_NAME)
      drop_trigger(:p_ci_pipelines, BEFORE_UPDATE_IID_TRIGGER_NAME)
      drop_trigger(:p_ci_pipelines, AFTER_DELETE_TRIGGER_NAME)
    end
    # rubocop: enable Migration/WithLockRetriesDisallowedMethod

    drop_function(BEFORE_INSERT_FUNCTION_NAME)
    drop_function(BEFORE_UPDATE_IID_FUNCTION_NAME)
    drop_function(AFTER_DELETE_FUNCTION_NAME)
  end
end
