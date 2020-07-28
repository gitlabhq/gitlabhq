# frozen_string_literal: true

class UnconfirmWrongfullyVerifiedEmails < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INTERVAL = 5.minutes.to_i
  BATCH_SIZE = 500
  MIGRATION = 'WrongfullyConfirmedEmailUnconfirmer'
  EMAIL_INDEX_NAME = 'tmp_index_for_email_unconfirmation_migration'

  class ApplicationSetting < ActiveRecord::Base
    self.table_name = 'application_settings'
  end

  class Email < ActiveRecord::Base
    include EachBatch
  end

  def up
    add_concurrent_index :emails, :id, where: 'confirmed_at IS NOT NULL', name: EMAIL_INDEX_NAME

    ApplicationSetting.reset_column_information

    setting_record = ApplicationSetting.last
    return unless setting_record&.send_user_confirmation_email

    queue_background_migration_jobs_by_range_at_intervals(Email,
                                                          MIGRATION,
                                                          INTERVAL,
                                                          batch_size: BATCH_SIZE)
  end

  def down
    remove_concurrent_index_by_name(:emails, EMAIL_INDEX_NAME)
  end
end
