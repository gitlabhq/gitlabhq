# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MigrateTriggerIdToPipeline < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    execute("UPDATE ci_commits SET " +
      "trigger_id = triggers.trigger_id, " +
      "trigger_variables = triggers.variables " +
      "FROM (SELECT commit_id, trigger_id, variables FROM ci_trigger_requests) as triggers " +
      "WHERE ci_commits.id = triggers.commit_id")
  end
end
