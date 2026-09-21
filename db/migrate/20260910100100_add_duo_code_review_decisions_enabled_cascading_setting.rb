# frozen_string_literal: true

class AddDuoCodeReviewDecisionsEnabledCascadingSetting < Gitlab::Database::Migration[2.3]
  milestone '19.5'
  disable_ddl_transaction!

  include Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings

  def up
    add_cascading_namespace_setting :duo_code_review_decisions_enabled, :boolean, default: true, null: false
  end

  def down
    remove_cascading_namespace_setting :duo_code_review_decisions_enabled
  end
end
