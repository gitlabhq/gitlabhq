# frozen_string_literal: true

class FixNotNullCheckConstraintInconsistency < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    table = :application_settings

    %i(container_registry_vendor container_registry_version).each do |column|
      change_column_null table, column, false
      remove_not_null_constraint(table, column) if check_not_null_constraint_exists?(table, column)
    end
  end

  def down
    # No-op: for regular systems without the inconsistency, #up is a no-op, too
  end
end
