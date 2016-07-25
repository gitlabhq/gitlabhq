# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MigrateMergeParamsCommitMessage < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    require 'yaml'

    db.select_all("SELECT id, merge_params FROM merge_requests WHERE merge_params LIKE '%commit_message%'").each do |result|
      commit_message = YAML.load(result['merge_params'])['commit_message']

      db.update("UPDATE merge_requests SET commit_message = #{db.quote(commit_message)} WHERE id = #{db.quote(result['id'])}")
    end
  end

  def down
    # In a migration right after this one, the column will be dropped, so I won't
    # implement this here
  end

  private

  def db
    ActiveRecord::Base.connection
  end
end
