# frozen_string_literal: true

class UnconfirmWrongfullyVerifiedEmails < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INTERVAL = 5.minutes.to_i
  BATCH_SIZE = 1000
  MIGRATION = 'WrongfullyConfirmedEmailUnconfirmer'
  EMAIL_INDEX_NAME = 'tmp_index_for_email_unconfirmation_migration'

  class Email < ActiveRecord::Base
    include EachBatch
  end

  def up
    add_concurrent_index :emails, :id, where: 'confirmed_at IS NOT NULL', name: EMAIL_INDEX_NAME

    queue_background_migration_jobs_by_range_at_intervals(Email,
                                                          MIGRATION,
                                                          INTERVAL,
                                                          batch_size: BATCH_SIZE)
  end

  def down
    remove_concurrent_index_by_name(:emails, EMAIL_INDEX_NAME)
  end
end
