# frozen_string_literal: true

class UpdateFingerprintSha256WithinKeys < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  class Key < ActiveRecord::Base
    include EachBatch

    self.table_name = 'keys'
    self.inheritance_column = :_type_disabled
  end

  disable_ddl_transaction!

  def up
    queue_background_migration_jobs_by_range_at_intervals(Key, 'MigrateFingerprintSha256WithinKeys', 5.minutes)
  end

  def down
    # no-op
  end
end
