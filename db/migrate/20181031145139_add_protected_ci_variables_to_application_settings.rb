# frozen_string_literal: true

class AddProtectedCiVariablesToApplicationSettings < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:application_settings, :protected_ci_variables, :boolean, default: false, allow_null: false)
  end

  def down
    remove_column(:application_settings, :protected_ci_variables)
  end
end
