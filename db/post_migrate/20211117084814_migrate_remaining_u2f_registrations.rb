# frozen_string_literal: true

class MigrateRemainingU2fRegistrations < Gitlab::Database::Migration[1.0]
  BATCH_SIZE = 100

  disable_ddl_transaction!

  def up
    # We expect only a few number of records satisfying these conditions.
    # on gitlab.com database, this number is 70 as on 17th Nov, 2021.
    define_batchable_model('u2f_registrations')
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
    # no-op
  end
end
