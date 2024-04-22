# frozen_string_literal: true

class MigrateContainerProtectionRulesMinimumAccessLevel < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  DEVELOPER = 30
  MAINTAINER = 40
  OWNER = 50
  ADMIN = 60

  class ContainerProtectionRule < MigrationRecord
    self.table_name = 'container_registry_protection_rules'
  end

  def migrate_minimum_access_level_for_push(old_access_level, new_access_level)
    ContainerProtectionRule.where(push_protected_up_to_access_level: old_access_level)
                           .update_all(minimum_access_level_for_push: new_access_level)
  end

  def undo_migrate_minimum_access_level_for_push(old_access_level, new_access_level)
    ContainerProtectionRule.where(minimum_access_level_for_push: new_access_level)
                           .update_all(push_protected_up_to_access_level: old_access_level)
  end

  def migrate_minimum_access_level_for_delete(old_access_level, new_access_level)
    ContainerProtectionRule.where(delete_protected_up_to_access_level: old_access_level)
                           .update_all(minimum_access_level_for_delete: new_access_level)
  end

  def undo_migrate_minimum_access_level_for_delete(old_access_level, new_access_level)
    ContainerProtectionRule.where(minimum_access_level_for_delete: new_access_level)
                           .update_all(delete_protected_up_to_access_level: old_access_level)
  end

  def up
    migrate_minimum_access_level_for_push(OWNER, ADMIN)
    migrate_minimum_access_level_for_push(MAINTAINER, OWNER)
    migrate_minimum_access_level_for_push(DEVELOPER, MAINTAINER)

    migrate_minimum_access_level_for_delete(OWNER, ADMIN)
    migrate_minimum_access_level_for_delete(MAINTAINER, OWNER)
    migrate_minimum_access_level_for_delete(DEVELOPER, MAINTAINER)
  end

  def down
    undo_migrate_minimum_access_level_for_push(DEVELOPER, MAINTAINER)
    undo_migrate_minimum_access_level_for_push(MAINTAINER, OWNER)
    undo_migrate_minimum_access_level_for_push(OWNER, ADMIN)

    undo_migrate_minimum_access_level_for_delete(DEVELOPER, MAINTAINER)
    undo_migrate_minimum_access_level_for_delete(MAINTAINER, OWNER)
    undo_migrate_minimum_access_level_for_delete(OWNER, ADMIN)
  end
end
