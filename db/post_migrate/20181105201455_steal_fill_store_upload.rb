# frozen_string_literal: true

class StealFillStoreUpload < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 10_000

  disable_ddl_transaction!

  class Upload < ActiveRecord::Base
    include EachBatch

    self.table_name = 'uploads'
    self.inheritance_column = :_type_disabled # Disable STI
  end

  def up
    Gitlab::BackgroundMigration.steal('FillStoreUpload')

    Upload.where(store: nil).each_batch(of: BATCH_SIZE) do |batch|
      range = batch.pluck('MIN(id)', 'MAX(id)').first

      Gitlab::BackgroundMigration::FillStoreUpload.new.perform(*range)
    end
  end

  def down
    # noop
  end
end
