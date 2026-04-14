# frozen_string_literal: true

class AddBuiltInProjectTemplatesEnabledSetting < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings

  milestone '18.11'
  disable_ddl_transaction!

  def up
    add_cascading_namespace_setting :built_in_project_templates_enabled, :boolean, default: true, null: false
  end

  def down
    remove_cascading_namespace_setting :built_in_project_templates_enabled
  end
end
