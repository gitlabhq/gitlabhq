# frozen_string_literal: true

class ConsumeRemainingEncryptIntegrationPropertyJobs < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  BATCH_SIZE = 50

  def up
    Gitlab::BackgroundMigration.steal('EncryptIntegrationProperties')

    model = define_batchable_model('integrations')
    relation = model.where.not(properties: nil).where(encrypted_properties: nil)

    relation.each_batch(of: BATCH_SIZE) do |batch|
      range = batch.pick('MIN(id)', 'MAX(id)')

      Gitlab::BackgroundMigration::EncryptIntegrationProperties.new.perform(*range)
    end
  end

  def down
  end
end
