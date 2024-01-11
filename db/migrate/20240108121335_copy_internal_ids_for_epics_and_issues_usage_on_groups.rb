# frozen_string_literal: true

class CopyInternalIdsForEpicsAndIssuesUsageOnGroups < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::SchemaHelpers

  milestone '16.8'
  disable_ddl_transaction!

  TRIGGER_ON_INSERT = 'trigger_copy_usage_on_internal_ids_on_insert'
  TRIGGER_ON_UPDATE = 'trigger_copy_usage_on_internal_ids_on_update'
  INSERT_OR_UPDATE_FUNCTION_NAME = 'insert_or_update_internal_ids_usage'

  def up
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{INSERT_OR_UPDATE_FUNCTION_NAME}()
        RETURNS trigger
        LANGUAGE plpgsql
      AS $$
        DECLARE
          namespace_type varchar;
          copy_usage smallint;
        BEGIN
          IF (NEW.usage = 0) THEN
            copy_usage = 4;

            -- we only care about group level internal_ids so we check namespace type here
            namespace_type = (SELECT type FROM namespaces WHERE id = NEW.namespace_id);
            IF (namespace_type <> 'Group') THEN
              RETURN NULL;
            END IF;
          ELSIF (NEW.usage = 4) THEN
            copy_usage = 0;
          ELSE
            RETURN NULL;
          END IF;

          -- if value is the same there is nothing to update
          IF (OLD.last_value = NEW.last_value AND (TG_OP = 'INSERT' OR TG_OP = 'UPDATE')) THEN
            RETURN NULL;
          END IF;

          INSERT INTO internal_ids (usage, last_value, namespace_id)
          VALUES (copy_usage, NEW.last_value, NEW.namespace_id)
          ON CONFLICT (usage, namespace_id) WHERE namespace_id IS NOT NULL
          DO UPDATE SET last_value = NEW.last_value;

          RETURN NULL;
        END
      $$
    SQL

    execute(<<~SQL)
      CREATE TRIGGER #{TRIGGER_ON_INSERT}
      AFTER INSERT ON internal_ids
      FOR EACH ROW
      WHEN (((NEW.usage = 0) OR (NEW.usage = 4)) AND NEW.namespace_id IS NOT NULL)
      EXECUTE FUNCTION #{INSERT_OR_UPDATE_FUNCTION_NAME}();
    SQL

    execute(<<~SQL)
      CREATE TRIGGER #{TRIGGER_ON_UPDATE}
      AFTER UPDATE ON internal_ids
      FOR EACH ROW
      WHEN (((NEW.usage = 0) OR (NEW.usage = 4)) AND NEW.namespace_id IS NOT NULL)
      EXECUTE FUNCTION #{INSERT_OR_UPDATE_FUNCTION_NAME}();
    SQL
  end

  def down
    drop_trigger(:internal_ids, TRIGGER_ON_INSERT)
    drop_trigger(:internal_ids, TRIGGER_ON_UPDATE)
    drop_function(INSERT_OR_UPDATE_FUNCTION_NAME)
  end
end
