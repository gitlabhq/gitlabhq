# frozen_string_literal: true

class AddAutoDuoCodeReviewEnabledCascadingSetting < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  disable_ddl_transaction!

  include Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings

  def up
    add_cascading_namespace_setting :auto_duo_code_review_enabled, :boolean, default: false, null: false
  end

  def down
    remove_cascading_namespace_setting :auto_duo_code_review_enabled
  end
end
