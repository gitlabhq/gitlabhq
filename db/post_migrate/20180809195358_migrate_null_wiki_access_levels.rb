# frozen_string_literal: true

class MigrateNullWikiAccessLevels < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  class ProjectFeature < ActiveRecord::Base
    include EachBatch

    self.table_name = 'project_features'
  end

  def up
    ProjectFeature.where(wiki_access_level: nil).each_batch do |relation|
      relation.update_all(wiki_access_level: 20)
    end
  end

  def down
    # there is no way to rollback this change, there are no downsides in keeping migrated data.
  end
end
