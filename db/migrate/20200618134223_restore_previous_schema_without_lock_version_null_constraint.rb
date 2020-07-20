# frozen_string_literal: true

class RestorePreviousSchemaWithoutLockVersionNullConstraint < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  TABLES = %i(epics merge_requests issues ci_stages ci_builds ci_pipelines).freeze

  disable_ddl_transaction!

  def up
    TABLES.each do |table|
      remove_not_null_constraint table, :lock_version
    end
  end

  def down
    # no-op
  end
end
