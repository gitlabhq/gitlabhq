# frozen_string_literal: true

class MigrateNullWikiAccessLevels < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class ProjectFeature < ActiveRecord::Base
    include EachBatch

    self.table_name = 'project_features'
  end

  def up
    ProjectFeature.where(wiki_access_level: nil).each_batch do |relation|
      relation.update_all(wiki_access_level: 20)
    end

    # We need to re-count wikis as previous attempt was not considering the NULLs.
    transaction do
      execute('SET LOCAL statement_timeout TO 0') # see https://gitlab.com/gitlab-org/gitlab-foss/issues/48967

      execute("UPDATE site_statistics SET wikis_count = (SELECT COUNT(*) FROM project_features WHERE wiki_access_level != 0)")
    end
  end

  def down
    # there is no way to rollback this change, there are no downsides in keeping migrated data.
  end
end
