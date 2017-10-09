# rubocop:disable Migration/UpdateColumnInBatches
class MakeProjectOwnersMasters < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    update_column_in_batches(:members, :access_level, 40) do |table, query|
      query.where(table[:access_level].eq(50).and(table[:source_type].eq('Project')))
    end
  end

  def down
    # do nothing
  end
end
