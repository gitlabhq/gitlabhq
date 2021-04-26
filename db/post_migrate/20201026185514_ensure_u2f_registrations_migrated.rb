# frozen_string_literal: true

class EnsureU2fRegistrationsMigrated < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  BACKGROUND_MIGRATION_CLASS = 'MigrateU2fWebauthn'
  BATCH_SIZE = 100
  DOWNTIME = false

  disable_ddl_transaction!

  class U2fRegistration < ActiveRecord::Base
    include EachBatch

    self.table_name = 'u2f_registrations'
  end

  def up
    Gitlab::BackgroundMigration.steal(BACKGROUND_MIGRATION_CLASS)

    # Do a manual update in case we lost BG jobs. The expected record count should be 0 or very low.
    U2fRegistration
        .joins("LEFT JOIN webauthn_registrations ON webauthn_registrations.u2f_registration_id = u2f_registrations.id")
        .where(webauthn_registrations: { u2f_registration_id: nil })
        .each_batch(of: BATCH_SIZE) do |batch, index|
      batch.each do |record|
        Gitlab::BackgroundMigration::MigrateU2fWebauthn.new.perform(record.id, record.id)
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e, u2f_registration_id: record.id)
      end
    end
  end

  def down
    # no-op (we can't "unsteal" migrations)
  end
end
