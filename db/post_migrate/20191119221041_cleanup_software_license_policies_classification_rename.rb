# frozen_string_literal: true

class CleanupSoftwareLicensePoliciesClassificationRename < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :software_license_policies, :approval_status, :classification
  end

  def down
    undo_cleanup_concurrent_column_rename :software_license_policies, :approval_status, :classification
  end
end
