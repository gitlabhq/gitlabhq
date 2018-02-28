# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class PopulateCanPushFromDeployKeysProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false
  DATABASE_NAME = Gitlab::Database.database_name

  disable_ddl_transaction!

  class DeploysKeyProject < ActiveRecord::Base
    include EachBatch

    self.table_name = 'deploy_keys_projects'
  end

  def up
    DeploysKeyProject.each_batch(of: 10_000) do |batch|
      start_id, end_id = batch.pluck('MIN(id), MAX(id)').first

      if Gitlab::Database.mysql?
        execute <<-EOF.strip_heredoc
          UPDATE deploy_keys_projects, #{DATABASE_NAME}.keys
          SET deploy_keys_projects.can_push = #{DATABASE_NAME}.keys.can_push
          WHERE deploy_keys_projects.deploy_key_id = #{DATABASE_NAME}.keys.id
          AND deploy_keys_projects.id BETWEEN #{start_id} AND #{end_id}
        EOF
      else
        execute <<-EOF.strip_heredoc
          UPDATE deploy_keys_projects
          SET can_push = keys.can_push
          FROM keys
          WHERE deploy_key_id = keys.id
          AND deploy_keys_projects.id BETWEEN #{start_id} AND #{end_id}
        EOF
      end
    end
  end

  def down
    DeploysKeyProject.each_batch(of: 10_000) do |batch|
      start_id, end_id = batch.pluck('MIN(id), MAX(id)').first

      if Gitlab::Database.mysql?
        execute <<-EOF.strip_heredoc
          UPDATE deploy_keys_projects, #{DATABASE_NAME}.keys
          SET #{DATABASE_NAME}.keys.can_push = deploy_keys_projects.can_push
          WHERE deploy_keys_projects.deploy_key_id = #{DATABASE_NAME}.keys.id
          AND deploy_keys_projects.id BETWEEN #{start_id} AND #{end_id}
        EOF
      else
        execute <<-EOF.strip_heredoc
          UPDATE keys
          SET can_push = deploy_keys_projects.can_push
          FROM deploy_keys_projects
          WHERE deploy_keys_projects.deploy_key_id = keys.id
          AND deploy_keys_projects.id BETWEEN #{start_id} AND #{end_id}
        EOF
      end
    end
  end
end
