# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveProjectLabelsGroupId < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    update_column_in_batches(:labels, :group_id, nil) do |table, query|
      query.where(table[:type].eq('ProjectLabel').and(table[:group_id].not_eq(nil)))
    end
  end

  def down
  end
end
