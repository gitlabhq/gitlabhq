# frozen_string_literal: true

class AddAutoDuoCodeReviewOnPushEnabledCascadingSetting < Gitlab::Database::Migration[2.3]
  milestone '19.5'
  disable_ddl_transaction!

  include Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings

  def up
    add_cascading_namespace_setting :auto_duo_code_review_on_push_enabled, :boolean, default: true, null: false

    add_column :project_settings, :auto_duo_code_review_on_push_enabled, :boolean, if_not_exists: true
  end

  def down
    remove_column :project_settings, :auto_duo_code_review_on_push_enabled, if_exists: true

    remove_cascading_namespace_setting :auto_duo_code_review_on_push_enabled
  end
end
