# frozen_string_literal: true

class AddTriggersForWorkItemCustomTypesExistenceCheck < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  FIRES = 'BEFORE INSERT OR UPDATE OF work_item_type_id'
  CUSTOM_TYPE_CHECK_FUNCTION = 'check_work_item_custom_type_exists'
  TRIGGER_FUNCTION = 'validate_work_item_type_id_is_valid'
  ISSUES_TRIGGER = 'validate_work_item_type_on_insert_or_update_issues'
  LIFECYCLES_TRIGGER = 'validate_work_item_type_on_insert_or_update_custom_lifecycles'
  STATUS_MAPPINGS_TRIGGER = 'validate_work_item_type_on_insert_or_update_status_mappings'
  CUSTOM_FIELDS_TRIGGER = 'validate_work_item_type_on_insert_or_update_custom_fields'
  USER_PREFERENCES_TRIGGER = 'validate_work_item_type_on_insert_or_update_work_item_user_preferences'

  milestone '18.10'
  disable_ddl_transaction!

  def up
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{CUSTOM_TYPE_CHECK_FUNCTION}(custom_type_id bigint)
      RETURNS boolean
      LANGUAGE plpgsql
      VOLATILE
      PARALLEL SAFE
      COST 1
      AS $$
      BEGIN
        PERFORM 1
        FROM work_item_custom_types
        WHERE id = $1
        FOR KEY SHARE;

        RETURN FOUND;
      END;
      $$;
    SQL

    create_trigger_function(TRIGGER_FUNCTION) do
      <<~SQL
        IF NEW.work_item_type_id >= 1001 THEN
          IF NOT #{CUSTOM_TYPE_CHECK_FUNCTION}(NEW.work_item_type_id) THEN
            RAISE EXCEPTION
              'Specified custom work item type does not exist: %',
              NEW.work_item_type_id;
          END IF;
        ELSIF NEW.work_item_type_id > 9 THEN
          RAISE EXCEPTION
            'Specified system defined work item type does not exist: %',
            NEW.work_item_type_id;
        END IF;

        RETURN NEW;
      SQL
    end

    create_trigger(:issues, ISSUES_TRIGGER, TRIGGER_FUNCTION, fires: FIRES, replace: true)
    create_trigger(:work_item_type_custom_lifecycles, LIFECYCLES_TRIGGER, TRIGGER_FUNCTION, fires: FIRES, replace: true)
    create_trigger(
      :work_item_custom_status_mappings, STATUS_MAPPINGS_TRIGGER, TRIGGER_FUNCTION, fires: FIRES, replace: true
    )
    create_trigger(:work_item_type_custom_fields, CUSTOM_FIELDS_TRIGGER, TRIGGER_FUNCTION, fires: FIRES, replace: true)
    create_trigger(
      :work_item_type_user_preferences, USER_PREFERENCES_TRIGGER, TRIGGER_FUNCTION, fires: FIRES, replace: true
    )
  end

  def down
    drop_trigger(:issues, ISSUES_TRIGGER)
    drop_trigger(:work_item_type_custom_lifecycles, LIFECYCLES_TRIGGER)
    drop_trigger(:work_item_custom_status_mappings, STATUS_MAPPINGS_TRIGGER)
    drop_trigger(:work_item_type_custom_fields, CUSTOM_FIELDS_TRIGGER)
    drop_trigger(:work_item_type_user_preferences, USER_PREFERENCES_TRIGGER)
    drop_function(TRIGGER_FUNCTION)

    execute(<<~SQL)
      DROP FUNCTION IF EXISTS #{CUSTOM_TYPE_CHECK_FUNCTION}
    SQL
  end
end
