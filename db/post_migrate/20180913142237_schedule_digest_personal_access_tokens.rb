class ScheduleDigestPersonalAccessTokens < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  BATCH_SIZE = 10_000
  MIGRATION = 'DigestColumn'
  DELAY_INTERVAL = 5.minutes.to_i

  disable_ddl_transaction!

  class PersonalAccessToken < ActiveRecord::Base
    include EachBatch

    self.table_name = 'personal_access_tokens'
  end

  def up
    PersonalAccessToken.where('token is NOT NULL').each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pluck('MIN(id)', 'MAX(id)').first
      BackgroundMigrationWorker.perform_in(index * DELAY_INTERVAL, MIGRATION, ['PersonalAccessToken', :token, :token_digest, *range])
    end
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end
end
