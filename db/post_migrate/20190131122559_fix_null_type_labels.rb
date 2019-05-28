# frozen_string_literal: true

class FixNullTypeLabels < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    update_column_in_batches(:labels, :type, 'ProjectLabel') do |table, query|
      query.where(
        table[:project_id].not_eq(nil)
          .and(table[:template].eq(false))
          .and(table[:type].eq(nil))
      )
    end
  end

  def down
    # no action
  end
end
