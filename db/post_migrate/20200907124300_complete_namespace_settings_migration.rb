# frozen_string_literal: true

class CompleteNamespaceSettingsMigration < ActiveRecord::Migration[5.2]
  DOWNTIME = false
  BATCH_SIZE = 10000

  class Namespace < ActiveRecord::Base
    include EachBatch

    self.table_name = 'namespaces'
  end

  def up
    Gitlab::BackgroundMigration.steal('BackfillNamespaceSettings')

    ensure_data_migration
  end

  def down
    # no-op
  end

  private

  def ensure_data_migration
    Namespace.each_batch(of: BATCH_SIZE) do |query|
      missing_count = query.where("NOT EXISTS (SELECT 1 FROM namespace_settings WHERE namespace_settings.namespace_id=namespaces.id)").limit(1).size
      if missing_count > 0
        min, max = query.pluck("MIN(id), MAX(id)").flatten
        # we expect low record count so inline execution is fine.
        Gitlab::BackgroundMigration::BackfillNamespaceSettings.new.perform(min, max)
      end
    end
  end
end
