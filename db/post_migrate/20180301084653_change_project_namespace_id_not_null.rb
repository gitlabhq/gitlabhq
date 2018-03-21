# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ChangeProjectNamespaceIdNotNull < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  class Project < ActiveRecord::Base
    self.table_name = 'projects'
    include EachBatch
  end

  BATCH_SIZE = 1000

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    Project.where(namespace_id: nil).each_batch(of: BATCH_SIZE) do |batch|
      batch.delete_all
    end

    change_column_null :projects, :namespace_id, false
  end

  def down
    change_column_null :projects, :namespace_id, true
  end
end
