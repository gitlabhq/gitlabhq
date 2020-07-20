# frozen_string_literal: true

class DropPartitionsDynamicSchemaIfExists < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    # This targets GitLab.com only - we deployed a migration to create this schema, but reverted the change
    execute 'DROP SCHEMA IF EXISTS partitions_dynamic'
  end

  def down
    # no-op
  end
end
