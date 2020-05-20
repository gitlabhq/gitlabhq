# frozen_string_literal: true

class AddActiveJobsLimitToPlans < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :plans, :active_jobs_limit, :integer, default: 0 # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column :plans, :active_jobs_limit
  end
end
