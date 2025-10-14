# frozen_string_literal: true

class SetAllowImmediateNamespacesDeletionToFalseOnSaasBis < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class MigrationApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'

    jsonb_accessor :namespace_deletion_settings,
      allow_immediate_namespaces_deletion: [:boolean, { default: true }]
  end

  def up
    return unless should_run?

    # On GitLab.com and Dedicated we don't allow bypassing deletion retention period
    MigrationApplicationSetting.last.update!(allow_immediate_namespaces_deletion: false)
  end

  def down
    return unless should_run?

    # Revert back to the default value
    MigrationApplicationSetting.last.update!(allow_immediate_namespaces_deletion: true)
  end

  private

  def should_run?
    MigrationApplicationSetting.last.present? &&
      (Gitlab.com? || MigrationApplicationSetting.last.gitlab_dedicated_instance)
  end
end
