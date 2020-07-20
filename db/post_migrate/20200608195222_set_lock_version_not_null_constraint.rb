# frozen_string_literal: true

class SetLockVersionNotNullConstraint < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  TABLES = %i(epics merge_requests issues ci_stages ci_builds ci_pipelines).freeze

  def up
    TABLES.each do |table|
      add_not_null_constraint table, :lock_version, validate: false
    end
  end

  def down
    TABLES.each do |table|
      remove_not_null_constraint table, :lock_version
    end
  end
end
