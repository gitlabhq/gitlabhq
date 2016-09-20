class SetProjectLabelTypeOnLabels < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    update_column_in_batches(:labels, :type, 'ProjectLabel') do |table, query|
      query.where(table[:project_id].not_eq(nil))
    end
  end

  def down
    update_column_in_batches(:labels, :type, nil) do |table, query|
      query.where(table[:project_id].not_eq(nil))
    end
  end
end
