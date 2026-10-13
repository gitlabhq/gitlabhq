# frozen_string_literal: true

class AddDuoCodeReviewApprovalCountsEnabledCascadingSetting < Gitlab::Database::Migration[2.3]
  milestone '19.5'
  disable_ddl_transaction!

  include Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings

  def up
    add_cascading_namespace_setting :duo_code_review_approval_counts_enabled, :boolean, default: false, null: false
  end

  def down
    remove_cascading_namespace_setting :duo_code_review_approval_counts_enabled
  end
end
