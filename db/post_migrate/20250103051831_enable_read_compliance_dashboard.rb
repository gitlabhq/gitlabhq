# frozen_string_literal: true

class EnableReadComplianceDashboard < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.9'

  def up
    sql = <<~SQL
      UPDATE member_roles
      SET permissions = jsonb_set(permissions::jsonb, '{"read_compliance_dashboard"}', 'true')::json
      WHERE permissions @> '{"admin_compliance_framework": true }'
    SQL

    execute(sql)
  end

  def down; end
end
