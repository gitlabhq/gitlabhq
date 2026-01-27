# frozen_string_literal: true

class AddTriggerForProjectSecretsManagerMaintenanceTasksOrganizationId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  milestone '18.9'

  TABLE_NAME = 'project_secrets_manager_maintenance_tasks'
  TRIGGER_FUNCTION_NAME = 'project_secrets_manager_maintenance_tasks_organization_id'
  TRIGGER_NAME = "trigger_#{TRIGGER_FUNCTION_NAME}"

  def up
    # Create trigger function
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{TRIGGER_FUNCTION_NAME}() RETURNS TRIGGER AS $$
      BEGIN
        IF NEW.organization_id IS NULL THEN
          SELECT organization_id
          INTO NEW.organization_id
          FROM users
          WHERE users.id = NEW.user_id;
        END IF;

        RETURN NEW;
      END
      $$ LANGUAGE PLPGSQL
    SQL

    # Create trigger
    create_trigger(
      TABLE_NAME,
      TRIGGER_NAME,
      TRIGGER_FUNCTION_NAME,
      fires: 'BEFORE INSERT OR UPDATE'
    )
  end

  def down
    drop_trigger(TABLE_NAME, TRIGGER_NAME)
    drop_function(TRIGGER_FUNCTION_NAME)
  end
end
