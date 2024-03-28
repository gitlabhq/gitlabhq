# frozen_string_literal: true

class CopyPermissionsOnMemberRoles < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::SchemaHelpers

  milestone '16.11'
  disable_ddl_transaction!

  FUNCTION_NAME = 'copy_member_roles_permissions'
  TRIGGER_NAME = 'trigger_copy_member_roles_permissions'

  def up
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{FUNCTION_NAME}()
        RETURNS trigger
        LANGUAGE plpgsql
      AS $$
        BEGIN
          -- when permissions have not changed
          IF (current_query() !~ '\\ypermissions\\y') THEN
            NEW.permissions = to_jsonb ((
              SELECT
                perm_cols
              FROM (
                SELECT
                  NEW.admin_cicd_variables,
                  NEW.admin_group_member,
                  NEW.admin_merge_request,
                  NEW.admin_terraform_state,
                  NEW.admin_vulnerability,
                  NEW.archive_project,
                  NEW.manage_group_access_tokens,
                  NEW.manage_project_access_tokens,
                  NEW.read_code,
                  NEW.read_dependency,
                  NEW.read_vulnerability,
                  NEW.remove_group,
                  NEW.remove_project) perm_cols));
          -- when permissions have changed
          ELSIF NEW.permissions <> '{}'::jsonb THEN
            NEW.admin_cicd_variables = COALESCE((NEW.permissions->'admin_cicd_variables')::BOOLEAN, FALSE);
            NEW.admin_group_member = COALESCE((NEW.permissions->'admin_group_member')::BOOLEAN, FALSE);
            NEW.admin_merge_request = COALESCE((NEW.permissions->'admin_merge_request')::BOOLEAN, FALSE);
            NEW.admin_terraform_state = COALESCE((NEW.permissions->'admin_terraform_state')::BOOLEAN, FALSE);
            NEW.admin_vulnerability = COALESCE((NEW.permissions->'admin_vulnerability')::BOOLEAN, FALSE);
            NEW.archive_project = COALESCE((NEW.permissions->'archive_project')::BOOLEAN, FALSE);
            NEW.manage_group_access_tokens = COALESCE((NEW.permissions->'manage_group_access_tokens')::BOOLEAN, FALSE);
            NEW.manage_project_access_tokens = COALESCE((NEW.permissions->'manage_project_access_tokens')::BOOLEAN, FALSE);
            NEW.read_code = COALESCE((NEW.permissions->'read_code')::BOOLEAN, FALSE);
            NEW.read_dependency = COALESCE((NEW.permissions->'read_dependency')::BOOLEAN, FALSE);
            NEW.read_vulnerability = COALESCE((NEW.permissions->'read_vulnerability')::BOOLEAN, FALSE);
            NEW.remove_group = COALESCE((NEW.permissions->'remove_group')::BOOLEAN, FALSE);
            NEW.remove_project = COALESCE((NEW.permissions->'remove_project')::BOOLEAN, FALSE);
          END IF;
          RETURN NEW;
        END;
      $$
    SQL

    drop_trigger(:member_roles, TRIGGER_NAME)
    execute(<<~SQL)
      CREATE TRIGGER #{TRIGGER_NAME}
      BEFORE INSERT OR UPDATE ON member_roles
      FOR EACH ROW
      EXECUTE FUNCTION #{FUNCTION_NAME}();
    SQL
  end

  def down
    drop_trigger(:member_roles, TRIGGER_NAME)
    drop_function(FUNCTION_NAME)
  end
end
