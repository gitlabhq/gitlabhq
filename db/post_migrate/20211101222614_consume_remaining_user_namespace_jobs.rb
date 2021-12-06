# frozen_string_literal: true

class ConsumeRemainingUserNamespaceJobs < Gitlab::Database::Migration[1.0]
  MIGRATION = 'BackfillUserNamespace'
  BATCH_SIZE = 200
  DEFAULT_VALUE = 'User'

  disable_ddl_transaction!

  def up
    Gitlab::BackgroundMigration.steal(MIGRATION)

    # Do a manual update in case we lost BG jobs. The expected record count should be 0 or very low.
    define_batchable_model('namespaces').where(type: nil).each_batch(of: BATCH_SIZE) do |batch|
      min, max = batch.pluck('MIN(id), MAX(id)').flatten

      Gitlab::BackgroundMigration::BackfillUserNamespace.new.perform(min, max, :namespaces, :id, BATCH_SIZE, 0)
    end

    change_column_null :namespaces, :type, false
  end

  def down
    change_column_null :namespaces, :type, true
  end
end
