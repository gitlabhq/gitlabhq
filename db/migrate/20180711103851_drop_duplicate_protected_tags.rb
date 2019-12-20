# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DropDuplicateProtectedTags < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  disable_ddl_transaction!

  BATCH_SIZE = 1000

  class Project < ActiveRecord::Base
    self.table_name = 'projects'

    include ::EachBatch
  end

  class ProtectedTag < ActiveRecord::Base
    self.table_name = 'protected_tags'
  end

  def up
    Project.each_batch(of: BATCH_SIZE) do |projects|
      ids = ProtectedTag
        .where(project_id: projects)
        .group(:name, :project_id)
        .select('max(id)')

      tags = ProtectedTag
        .where(project_id: projects)
        .where.not(id: ids)

      tags.delete_all
    end
  end

  def down
  end
end
