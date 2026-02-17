# frozen_string_literal: true

class CleanupFuzzTestingComplianceControls < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  CONTROL_NAME = 13
  BATCH_SIZE = 50

  def up
    define_batchable_model('compliance_requirements_controls')
      .where(name: CONTROL_NAME)
      .each_batch(of: BATCH_SIZE) do |batch|
      batch.delete_all
    end
  end

  def down
    # no-op: data cannot be restored
  end
end
