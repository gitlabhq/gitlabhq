# frozen_string_literal: true

class SetLockVersionToNotNull < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  TABLES = %w(epics merge_requests issues ci_stages ci_builds ci_pipelines).freeze
  BATCH_SIZE = 10_000

  disable_ddl_transaction!

  def declare_class(table)
    Class.new(ActiveRecord::Base) do
      include EachBatch

      self.table_name = table
      self.inheritance_column = :_type_disabled # Disable STI
    end
  end

  def up
    TABLES.each do |table|
      declare_class(table).where(lock_version: nil).each_batch(of: BATCH_SIZE) do |batch|
        batch.update_all(lock_version: 0)
      end
    end
  end

  def down
    # Nothing to do...
  end
end
