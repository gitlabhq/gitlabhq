# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class IssuesConfidentialNotNull < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  class Issue < ActiveRecord::Base
    self.table_name = 'issues'
  end

  def up
    Issue.where('confidential IS NULL').update_all(confidential: false)

    change_column_null :issues, :confidential, false
  end

  def down
    # There's no way / point to revert this.
  end
end
