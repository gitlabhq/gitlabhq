# frozen_string_literal: true

class AddRuntimeCreatedToCiJobVariables < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  DEFAULT_SOURCE = 0 # Equvalent to Ci::JobVariable.internal_source

  def up
    add_column_with_default(:ci_job_variables, :source, :integer, limit: 2, default: DEFAULT_SOURCE, allow_null: false) # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column(:ci_job_variables, :source)
  end
end
