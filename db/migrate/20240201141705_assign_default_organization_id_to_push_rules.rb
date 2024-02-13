# frozen_string_literal: true

class AssignDefaultOrganizationIdToPushRules < Gitlab::Database::Migration[2.2]
  DEFAULT_ORGANIZATION_ID = 1

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  enable_lock_retries!

  milestone '16.9'

  def up
    execute "UPDATE push_rules SET organization_id = #{DEFAULT_ORGANIZATION_ID} WHERE is_sample = true"
  end

  def down
    execute 'UPDATE push_rules SET organization_id = NULL WHERE is_sample = true'
  end
end
