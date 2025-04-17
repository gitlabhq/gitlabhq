# frozen_string_literal: true

class UpdateApplicationSettingDefaultScanExecutionPoliciesActionLimit < Gitlab::Database::Migration[2.2]
  milestone "18.0"
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute <<~SQL
      UPDATE application_settings
      SET security_policies = jsonb_set(
        security_policies,
        '{scan_execution_policies_action_limit}',
        '0'::jsonb,
        true -- create_missing
      );
    SQL
  end

  def down
    # irreversible
  end
end
