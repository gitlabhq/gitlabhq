# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MigrateSnippetsAccessLevelDefaultValue < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  ENABLED = 20

  disable_ddl_transaction!

  class ProjectFeature < ActiveRecord::Base
    include EachBatch

    self.table_name = 'project_features'
  end

  def up
    change_column_default :project_features, :snippets_access_level, ENABLED

    # On GitLab.com this will update about 28 000 rows. Since our updates are
    # very small and this column is not indexed, these updates should be very
    # lightweight.
    ProjectFeature.where(snippets_access_level: nil).each_batch do |batch|
      batch.update_all(snippets_access_level: ENABLED)
    end

    # We do not need to perform this in a post-deployment migration as the
    # ProjectFeature model already enforces a default value for all new rows.
    change_column_null :project_features, :snippets_access_level, false
  end

  def down
    change_column_null :project_features, :snippets_access_level, true
    change_column_default :project_features, :snippets_access_level, nil

    # We can't migrate from 20 -> NULL, as some projects may have explicitly set
    # the access level to 20.
  end
end
