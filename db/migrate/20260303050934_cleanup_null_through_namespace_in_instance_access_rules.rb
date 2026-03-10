# frozen_string_literal: true

class CleanupNullThroughNamespaceInInstanceAccessRules < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  milestone '18.10'

  class InstanceAccessRule < MigrationRecord
    include EachBatch

    self.table_name = 'ai_instance_accessible_entity_rules'
  end

  def up
    # no-op - required to allow rollback of AllowNullThroughNamespaceInInstanceAccessRules
  end

  def down
    InstanceAccessRule.each_batch do |relation|
      relation.where(through_namespace_id: nil).delete_all
    end
  end
end
