# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MergeIssuableReopenedIntoOpenedState < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Issue < ActiveRecord::Base
    self.table_name = 'issues'

    include EachBatch
  end

  class MergeRequest < ActiveRecord::Base
    self.table_name = 'merge_requests'

    include EachBatch
  end

  def up
    [Issue, MergeRequest].each do |model|
      say "Changing #{model.table_name}.state from 'reopened' to 'opened'"

      model.where(state: 'reopened').each_batch do |batch|
        batch.update_all(state: 'opened')
      end
    end
  end
end
