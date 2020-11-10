# frozen_string_literal: true

class EnsureNamespaceSettingsCreation < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 10000
  MIGRATION = 'BackfillNamespaceSettings'
  DELAY_INTERVAL = 2.minutes.to_i

  disable_ddl_transaction!

  class Namespace < ActiveRecord::Base
    include EachBatch

    self.table_name = 'namespaces'
  end

  def up
    ensure_data_migration
  end

  def down
    # no-op
  end

  private

  def ensure_data_migration
    Namespace.each_batch(of: BATCH_SIZE) do |query, index|
      missing_count = query.where("NOT EXISTS (SELECT 1 FROM namespace_settings WHERE namespace_settings.namespace_id=namespaces.id)").limit(1).size

      if missing_count > 0
        ids_range = query.pluck("MIN(id), MAX(id)").flatten

        migrate_in(index * DELAY_INTERVAL, MIGRATION, ids_range)
      end
    end
  end
end
