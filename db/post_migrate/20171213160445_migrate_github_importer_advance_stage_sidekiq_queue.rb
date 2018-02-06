# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MigrateGithubImporterAdvanceStageSidekiqQueue < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    sidekiq_queue_migrate 'github_importer_advance_stage', to: 'github_import_advance_stage'
  end

  def down
    sidekiq_queue_migrate 'github_import_advance_stage', to: 'github_importer_advance_stage'
  end
end
