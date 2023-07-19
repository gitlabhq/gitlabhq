# frozen_string_literal: true

class AddTriggerOnOrganizations < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::SchemaHelpers

  TABLE_NAME = 'organizations'
  FUNCTION_NAME = 'prevent_delete_of_default_organization'
  TRIGGER_NAME = 'prevent_delete_of_default_organization_before_destroy'

  def up
    default_org_id = Organizations::Organization::DEFAULT_ORGANIZATION_ID

    create_trigger_function(FUNCTION_NAME) do
      <<~SQL
        IF OLD.id = #{default_org_id} THEN
          RAISE EXCEPTION 'Deletion of the default Organization is not allowed.';
        END IF;
        RETURN OLD;
      SQL
    end

    create_trigger(TABLE_NAME, TRIGGER_NAME, FUNCTION_NAME, fires: 'BEFORE DELETE')
  end

  def down
    drop_trigger(TABLE_NAME, TRIGGER_NAME)
    drop_function(FUNCTION_NAME)
  end
end
