# frozen_string_literal: true

class EncryptWebHooksColumns < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  BATCH_SIZE = 10000
  RANGE_SIZE = 100
  MIGRATION = 'EncryptColumns'
  COLUMNS = [:token, :url]

  WebHook = ::Gitlab::BackgroundMigration::Models::EncryptColumns::WebHook

  disable_ddl_transaction!

  def up
    WebHook.each_batch(of: BATCH_SIZE) do |relation, index|
      delay = index * 2.minutes

      relation.each_batch(of: RANGE_SIZE) do |relation|
        range = relation.pluck('MIN(id)', 'MAX(id)').first
        args = [WebHook, COLUMNS, *range]

        BackgroundMigrationWorker.perform_in(delay, MIGRATION, args)
      end
    end
  end

  def down
    # noop
  end
end
