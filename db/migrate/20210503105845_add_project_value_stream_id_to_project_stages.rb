# frozen_string_literal: true

class AddProjectValueStreamIdToProjectStages < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_analytics_ca_project_stages_on_value_stream_id'

  class ProjectValueStream < ActiveRecord::Base
    self.table_name = 'analytics_cycle_analytics_project_stages'

    include EachBatch
  end

  def up
    ProjectValueStream.reset_column_information
    # The table was never used, there is no user-facing code that modifies the table, it should be empty.
    # Since there is no functionality present that depends on this data, it's safe to delete the rows.
    ProjectValueStream.each_batch(of: 100) do |relation|
      relation.delete_all
    end

    transaction do
      add_reference :analytics_cycle_analytics_project_stages, :project_value_stream, null: false, index: { name: INDEX_NAME }, foreign_key: { on_delete: :cascade, to_table: :analytics_cycle_analytics_project_value_streams }, type: :bigint # rubocop: disable Migration/AddReference, Rails/NotNullColumn
    end
  end

  def down
    remove_reference :analytics_cycle_analytics_project_stages, :project_value_stream
  end
end
