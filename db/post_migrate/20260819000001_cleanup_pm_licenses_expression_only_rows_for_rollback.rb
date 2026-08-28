# frozen_string_literal: true

class CleanupPmLicensesExpressionOnlyRowsForRollback < Gitlab::Database::Migration[2.3]
  milestone '19.4'
  restrict_gitlab_migration gitlab_schema: :gitlab_pm
  disable_ddl_transaction!

  def up
    # no-op
  end

  def down
    define_batchable_model('pm_licenses').where(spdx_identifier: nil).each_batch do |batch|
      batch.delete_all
    end
  end
end
