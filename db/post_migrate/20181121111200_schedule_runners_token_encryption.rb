# frozen_string_literal: true

class ScheduleRunnersTokenEncryption < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 10000
  RANGE_SIZE = 100
  MIGRATION = 'EncryptRunnersTokens'

  MODELS = [
    ::Gitlab::BackgroundMigration::Models::EncryptColumns::Settings,
    ::Gitlab::BackgroundMigration::Models::EncryptColumns::Namespace,
    ::Gitlab::BackgroundMigration::Models::EncryptColumns::Project,
    ::Gitlab::BackgroundMigration::Models::EncryptColumns::Runner
  ].freeze

  disable_ddl_transaction!

  def up
    MODELS.each do |model|
      model.each_batch(of: BATCH_SIZE) do |relation, index|
        delay = index * 2.minutes

        relation.each_batch(of: RANGE_SIZE) do |relation|
          range = relation.pluck('MIN(id)', 'MAX(id)').first
          args = [model, model.encrypted_attributes.keys, *range]

          BackgroundMigrationWorker.perform_in(delay, MIGRATION, args)
        end
      end
    end
  end

  def down
    # no-op
  end
end
