class MigrateIssuesToGhostUser < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  class User < ApplicationRecord
    self.table_name = 'users'
  end

  class Issue < ApplicationRecord
    self.table_name = 'issues'

    include ::EachBatch
  end

  def reset_column_in_migration_models
    ApplicationRecord.clear_cache!

    ::User.reset_column_information
    ::Namespace.reset_column_information
  end

  def up
    reset_column_in_migration_models

    # we use the model method because rewriting it is too complicated and would require copying multiple methods
    ghost_id = ::User.ghost.id

    Issue.where('NOT EXISTS (?)', User.unscoped.select(1).where('issues.author_id = users.id')).each_batch do |relation|
      relation.update_all(author_id: ghost_id)
    end
  end

  def down
  end
end
