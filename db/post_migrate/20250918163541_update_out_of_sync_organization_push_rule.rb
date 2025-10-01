# frozen_string_literal: true

class UpdateOutOfSyncOrganizationPushRule < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    execute <<-SQL
      UPDATE organization_push_rules
      SET id = pr.id
      FROM push_rules pr
      WHERE organization_push_rules.organization_id = pr.organization_id AND pr.is_sample = true
    SQL
  end

  def down
    execute <<-SQL
      UPDATE organization_push_rules
      SET id = nextval('organization_push_rules_id_seq')
    SQL
  end
end
